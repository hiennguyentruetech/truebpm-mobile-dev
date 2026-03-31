part of 'core_service.dart';

/// MIME type mapping for file operations
const Map<String, String> kMimeTypeMap = {
  // Documents
  'pdf': 'application/pdf',
  'rtf': 'application/rtf',
  'epub': 'application/epub+zip',
  // Word
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'docm': 'application/vnd.ms-word.document.macroEnabled.12',
  'dot': 'application/msword',
  'dotx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
  'dotm': 'application/vnd.ms-word.template.macroEnabled.12',
  // Excel
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'xlsm': 'application/vnd.ms-excel.sheet.macroEnabled.12',
  'xltx':
      'application/vnd.openxmlformats-officedocument.spreadsheetml.template',
  'xltm': 'application/vnd.ms-excel.template.macroEnabled.12',
  'xlam': 'application/vnd.ms-excel.addin.macroEnabled.12',
  'xlsb': 'application/vnd.ms-excel.sheet.binary.macroEnabled.12',
  'csv': 'text/csv',
  'tsv': 'text/tab-separated-values',
  // PowerPoint
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx':
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'pptm': 'application/vnd.ms-powerpoint.presentation.macroEnabled.12',
  'potx':
      'application/vnd.openxmlformats-officedocument.presentationml.template',
  'potm': 'application/vnd.ms-powerpoint.template.macroEnabled.12',
  'pps': 'application/vnd.ms-powerpoint',
  'ppsx':
      'application/vnd.openxmlformats-officedocument.presentationml.slideshow',
  'ppsm': 'application/vnd.ms-powerpoint.slideshow.macroEnabled.12',
  // OpenDocument
  'odt': 'application/vnd.oasis.opendocument.text',
  'ott': 'application/vnd.oasis.opendocument.text-template',
  'ods': 'application/vnd.oasis.opendocument.spreadsheet',
  'ots': 'application/vnd.oasis.opendocument.spreadsheet-template',
  'odp': 'application/vnd.oasis.opendocument.presentation',
  'otp': 'application/vnd.oasis.opendocument.presentation-template',
  // Images
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'bmp': 'image/bmp',
  'tiff': 'image/tiff',
  'tif': 'image/tiff',
  'webp': 'image/webp',
  'svg': 'image/svg+xml',
  'svgz': 'image/svg+xml',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'ico': 'image/x-icon',
  // Text/Code
  'txt': 'text/plain',
  'json': 'application/json',
  'xml': 'application/xml',
  'html': 'text/html',
  'htm': 'text/html',
  'md': 'text/markdown',
  'markdown': 'text/markdown',
  'yaml': 'application/x-yaml',
  'yml': 'application/x-yaml',
  'ini': 'text/plain',
  'log': 'text/plain',
  'css': 'text/css',
  'js': 'application/javascript',
  // Archives
  'zip': 'application/zip',
  'rar': 'application/vnd.rar',
  '7z': 'application/x-7z-compressed',
  'tar': 'application/x-tar',
  'gz': 'application/gzip',
  'tgz': 'application/gzip',
  'bz2': 'application/x-bzip2',
  'xz': 'application/x-xz',
  // Audio
  'mp3': 'audio/mpeg',
  'wav': 'audio/wav',
  'm4a': 'audio/mp4',
  'ogg': 'audio/ogg',
  'flac': 'audio/flac',
  'aac': 'audio/aac',
  // Video
  'mp4': 'video/mp4',
  'm4v': 'video/x-m4v',
  'mov': 'video/quicktime',
  'avi': 'video/x-msvideo',
  'mkv': 'video/x-matroska',
  'webm': 'video/webm',
};
