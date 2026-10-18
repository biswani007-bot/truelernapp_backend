import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/assignment_attachment_entity.dart';

/// Screen for viewing teacher-provided attachments and resources.
///
/// Features:
/// - Authenticated file retrieval using [Dio] and session tokens.
/// - In-app PDF viewing via [PDFView] with page indicator and pinch-to-zoom.
/// - In-app image viewing (JPG, JPEG, PNG, WEBP) with [InteractiveViewer].
/// - Safe external app handoff for Word documents (DOC, DOCX) via [OpenFilex].
/// - Temporary local file caching to prevent redundant network downloads.
/// - Clear loading and error states with user-friendly diagnostics and retry.
class AttachmentViewerScreen extends ConsumerStatefulWidget {
  final AssignmentAttachmentEntity attachment;
  final String assignmentTitle;

  const AttachmentViewerScreen({
    super.key,
    required this.attachment,
    this.assignmentTitle = 'Assignment',
  });

  /// Validates whether a remote host is a trusted TrueLern service or environment.
  @visibleForTesting
  static bool isTrustedHost(String host, String baseHost) {
    final lowerHost = host.toLowerCase();
    final lowerBase = baseHost.toLowerCase();

    if (lowerHost == lowerBase) return true;
    if (lowerHost.endsWith('.truelern.com') || lowerHost == 'truelern.com') {
      return true;
    }
    if (lowerHost.endsWith('.truelern.in') || lowerHost == 'truelern.in') {
      return true;
    }
    if (lowerHost.endsWith('.visital.in') || lowerHost == 'visital.in') {
      return true;
    }
    if (lowerHost == 'localhost' ||
        lowerHost == '127.0.0.1' ||
        lowerHost == '10.0.2.2') {
      return true;
    }
    return false;
  }

  /// Authoritatively resolves raw attachment paths or URLs against the configured backend base URL.
  @visibleForTesting
  static String? resolveAttachmentUrl(String fileUrl, String baseApiUrl) {
    final trimmed = fileUrl.trim();
    if (trimmed.isEmpty) return null;

    // 1. Preserve valid absolute URLs (HTTP or HTTPS)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        return null;
      }
      final baseUri = Uri.tryParse(baseApiUrl);
      if (baseUri != null && !isTrustedHost(uri.host, baseUri.host)) {
        // Prevent downloading from untrusted remote hosts
        return null;
      }
      return uri.toString();
    }

    // 2. Parse the base API URL to determine server origin and base path
    final baseUri = Uri.tryParse(baseApiUrl);
    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      return null;
    }

    // Server origin (e.g., "https://truelern.visital.in" from "https://truelern.visital.in/api")
    final serverOrigin = baseUri.origin;

    // Base API path without trailing slash (e.g. "/api")
    final baseApiPath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;

    // Normalize relative path
    final pathWithoutLeadingSlash = trimmed.startsWith('/')
        ? trimmed.substring(1)
        : trimmed;

    String resolved;

    // Check if relative path already contains the "api" prefix (e.g. "/api/..." or "api/...")
    if (pathWithoutLeadingSlash.startsWith('api/') ||
        pathWithoutLeadingSlash == 'api') {
      resolved = '$serverOrigin/$pathWithoutLeadingSlash';
    }
    // Check if the relative path points to static uploads (e.g. "/uploads/..." or "uploads/...")
    else if (pathWithoutLeadingSlash.startsWith('uploads/') ||
        pathWithoutLeadingSlash == 'uploads') {
      resolved = '$serverOrigin/$pathWithoutLeadingSlash';
    }
    // Root-relative path (e.g. "/files/...", "/static/...") -> resolve against server root origin
    else if (trimmed.startsWith('/')) {
      resolved = '$serverOrigin$trimmed';
    }
    // Standard relative API path -> resolve against configured base API URL
    else {
      final normalizedBase = '$serverOrigin$baseApiPath';
      resolved = '$normalizedBase/$pathWithoutLeadingSlash';
    }

    // Safely encode URI without double-encoding existing percent escapes or breaking query parameters
    try {
      final parsedUri = Uri.parse(resolved);
      return parsedUri.toString();
    } catch (_) {
      try {
        final parsedUri = Uri.parse(Uri.encodeFull(resolved));
        return parsedUri.toString();
      } catch (_) {
        return null;
      }
    }
  }

  @override
  ConsumerState<AttachmentViewerScreen> createState() =>
      _AttachmentViewerScreenState();
}

enum AttachmentViewType { pdf, image, word, other }

class _AttachmentViewerScreenState
    extends ConsumerState<AttachmentViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  File? _cachedFile;
  AttachmentViewType _viewType = AttachmentViewType.other;

  // PDF Viewer State
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _determineViewType();
    _loadAttachment();
  }

  void _determineViewType() {
    final name = widget.attachment.fileName.toLowerCase();
    final url = widget.attachment.fileUrl.toLowerCase();
    final type = widget.attachment.fileType.toLowerCase();

    if (name.endsWith('.pdf') || url.endsWith('.pdf') || type.contains('pdf')) {
      _viewType = AttachmentViewType.pdf;
    } else if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.webp') ||
        type.contains('image')) {
      _viewType = AttachmentViewType.image;
    } else if (name.endsWith('.doc') ||
        name.endsWith('.docx') ||
        url.endsWith('.doc') ||
        url.endsWith('.docx') ||
        type.contains('word') ||
        type.contains('officedocument')) {
      _viewType = AttachmentViewType.word;
    } else {
      _viewType = AttachmentViewType.other;
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\.-]'), '_');
  }

  String? _resolveFullUrl(String fileUrl, String baseApiUrl) {
    return AttachmentViewerScreen.resolveAttachmentUrl(fileUrl, baseApiUrl);
  }

  Future<void> _loadAttachment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appConfig = ref.read(appConfigProvider);
      final fullUrl = _resolveFullUrl(
        widget.attachment.fileUrl,
        appConfig.apiBaseUrl,
      );

      if (fullUrl == null) {
        throw Exception(
          'Invalid or untrusted attachment URL: ${widget.attachment.fileUrl}',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final sanitizedName = _sanitizeFileName(
        widget.attachment.fileName.isNotEmpty
            ? widget.attachment.fileName
            : 'attachment_${widget.attachment.id}',
      );
      final cacheId = widget.attachment.id.isNotEmpty
          ? widget.attachment.id
          : sanitizedName.hashCode.toString();
      final localFilePath =
          '${tempDir.path}/truelern_${cacheId}_$sanitizedName';
      final targetFile = File(localFilePath);

      // Check if file is already cached and non-empty
      if (await targetFile.exists() && (await targetFile.length()) > 0) {
        if (!mounted) return;
        setState(() {
          _cachedFile = targetFile;
          _isLoading = false;
        });

        if (_viewType == AttachmentViewType.word) {
          _openWithExternalApp(targetFile.path, silent: true);
        }
        return;
      }

      // Download file with authenticated Dio client
      final dio = ref.read(dioProvider);
      final response = await dio.get<List<int>>(
        fullUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Downloaded attachment is empty.');
      }

      await targetFile.writeAsBytes(bytes);

      if (!mounted) return;
      setState(() {
        _cachedFile = targetFile;
        _isLoading = false;
      });

      if (_viewType == AttachmentViewType.word) {
        _openWithExternalApp(targetFile.path, silent: true);
      }
    } on DioException catch (dioErr) {
      if (!mounted) return;
      String message = 'Unable to download attachment.';
      final statusCode = dioErr.response?.statusCode;

      if (statusCode == 404) {
        message =
            'Attachment not found on server (HTTP 404).\n'
            'The file may have been moved or removed by the teacher.';
      } else if (statusCode == 401) {
        message =
            'Authentication failed (HTTP 401).\n'
            'Please log in again to access this resource.';
      } else if (statusCode == 403) {
        message =
            'Access denied (HTTP 403).\n'
            'You do not have permission to view this attachment.';
      } else if (dioErr.type == DioExceptionType.connectionTimeout ||
          dioErr.type == DioExceptionType.receiveTimeout ||
          dioErr.type == DioExceptionType.connectionError) {
        message =
            'Network connection error.\n'
            'Please check your internet connection and try again.';
      } else {
        message = dioErr.message ?? 'Server error while retrieving attachment.';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openWithExternalApp(
    String filePath, {
    bool silent = false,
  }) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (!mounted) return;

      if (result.type == ResultType.noAppToOpen && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No compatible application installed to open this file format.',
            ),
            backgroundColor: Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result.type == ResultType.permissionDenied && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission denied to open file.'),
            backgroundColor: Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result.type != ResultType.done && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${result.message}'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open file: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadToDeviceStorage() async {
    if (_cachedFile == null || !await _cachedFile!.exists()) return;
    try {
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir != null) {
        final destPath = '${downloadsDir.path}/${widget.attachment.fileName}';
        await _cachedFile!.copy(destPath);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: ${widget.attachment.fileName}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (_cachedFile != null) {
        _openWithExternalApp(_cachedFile!.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.attachment.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (widget.attachment.displayFileSize.isNotEmpty)
              Text(
                widget.attachment.displayFileSize,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
          ],
        ),
        actions: [
          if (_cachedFile != null) ...[
            IconButton(
              key: const Key('attachment_download_button'),
              tooltip: 'Save to device',
              icon: const Icon(
                Icons.download_rounded,
                color: Color(0xFF0037B1),
                size: 22,
              ),
              onPressed: _downloadToDeviceStorage,
            ),
            IconButton(
              key: const Key('attachment_open_external_button'),
              tooltip: 'Open in external app',
              icon: const Icon(
                Icons.open_in_new_rounded,
                color: Color(0xFF0037B1),
                size: 22,
              ),
              onPressed: () => _openWithExternalApp(_cachedFile!.path),
            ),
          ],
        ],
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar:
          (_viewType == AttachmentViewType.pdf &&
              _totalPages > 0 &&
              !_isLoading &&
              _errorMessage == null)
          ? _buildPdfPageIndicator()
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0037B1)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Retrieving Attachment...',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.attachment.fileName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Attachment Unavailable',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loadAttachment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF0037B1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_cachedFile == null) {
      return const SizedBox.shrink();
    }

    switch (_viewType) {
      case AttachmentViewType.pdf:
        return _buildPdfView();
      case AttachmentViewType.image:
        return _buildImageView();
      case AttachmentViewType.word:
      case AttachmentViewType.other:
        return _buildDocumentFallbackView();
    }
  }

  Widget _buildPdfView() {
    return Stack(
      children: [
        PDFView(
          filePath: _cachedFile!.path,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 0;
            });
          },
          onError: (error) {
            setState(() {
              _errorMessage = 'PDF rendering error: $error';
            });
          },
          onPageError: (page, error) {
            setState(() {
              _errorMessage = 'Page $page rendering error: $error';
            });
          },
          onViewCreated: (PDFViewController controller) {
            _pdfViewController = controller;
          },
          onPageChanged: (int? page, int? total) {
            setState(() {
              _currentPage = page ?? 0;
              _totalPages = total ?? _totalPages;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPdfPageIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page ${_currentPage + 1} of $_totalPages',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  onPressed: _currentPage > 0
                      ? () {
                          _pdfViewController?.setPage(_currentPage - 1);
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                  onPressed: _currentPage < _totalPages - 1
                      ? () {
                          _pdfViewController?.setPage(_currentPage + 1);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageView() {
    return Container(
      color: const Color(0xFF0F172A),
      width: double.infinity,
      height: double.infinity,
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4.0,
        child: Center(
          child: Image.file(
            _cachedFile!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Text(
                'Failed to load image preview: $error',
                style: const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentFallbackView() {
    final isWord = _viewType == AttachmentViewType.word;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isWord
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWord
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Icon(
                  isWord
                      ? Icons.article_rounded
                      : Icons.insert_drive_file_rounded,
                  color: isWord
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF475569),
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.attachment.fileName,
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.attachment.displayFileSize.isNotEmpty
                    ? widget.attachment.displayFileSize
                    : 'External Document',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isWord
                    ? 'Word documents are opened safely using your installed document viewer app (such as Microsoft 365, Google Docs, or Office).'
                    : 'This file format is opened using your device’s compatible viewer app.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _openWithExternalApp(_cachedFile!.path),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  backgroundColor: const Color(0xFF0037B1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'Open in External Viewer',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
