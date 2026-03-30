part of 'tab_doc_core_body_screen.dart';

extension TabDocCoreBodyUiExt on _TabDocCoreBodyScreenState {
  Widget _buildUploadArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Always visible)
          // Make the whole header tappable with ripple
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _safeSetState(() {
                  _isUploadAreaExpanded = !_isUploadAreaExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.cloud_upload,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Documents',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Tap to expand upload options',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Selected files count badge
                    if (_selectedFiles.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedFiles.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isUploadAreaExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expandable content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isUploadAreaExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isUploadAreaExpanded ? 1.0 : 0.0,
              child: _isUploadAreaExpanded
                  ? Container(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        top: 5,
                      ),
                      child: Column(
                        children: [
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.folder_open,
                                  label: 'Files & Gallery',
                                  onTap: _pickFiles,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4FACFE),
                                      Color(0xFF00F2FE),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.camera_alt,
                                  label: 'Camera',
                                  onTap: _pickFromCamera,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFA709A),
                                      Color(0xFFFEE140),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Selected Files
                          if (_selectedFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildSelectedFilesList(),
                            const SizedBox(height: 12),
                            _buildUploadButton(),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required LinearGradient gradient,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: _isProcessing
              ? LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                )
              : gradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _isProcessing
              ? []
              : [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFilesList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(
                  _getFileIcon(file.name),
                  color: Colors.blue.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        softWrap: true,
                      ),
                      Text(
                        _formatFileSize(file.size),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      // Revision and Document Type dropdowns in same row
                      if (widget.enableRevision ||
                          widget.enableDocumentType) ...[
                        const SizedBox(height: 4),
                        _buildFileDropdownsRow(index),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeSelectedFile(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.red.shade400,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileDropdownsRow(int fileIndex) {
    return Row(
      children: [
        // Revision dropdown
        if (widget.enableRevision) ...[
          Expanded(child: _buildFileRevisionDropdown(fileIndex)),
          if (widget.enableDocumentType) const SizedBox(width: 6),
        ],
        // Document Type dropdown
        if (widget.enableDocumentType) ...[
          Expanded(child: _buildFileDocumentTypeDropdown(fileIndex)),
        ],
      ],
    );
  }

  Widget _buildFileRevisionDropdown(int fileIndex) {
    final file = _selectedFiles[fileIndex];
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: file.revisionId,
          hint: Text(
            'Revision',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          style: const TextStyle(fontSize: 10, color: Colors.black87),
          items: _revisionOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['id']?.toString(),
              child: Text(
                option['name']?.toString() ?? '',
                style: const TextStyle(fontSize: 10),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              final selectedOption = _revisionOptions.firstWhere(
                (option) => option['id']?.toString() == value,
                orElse: () => {},
              );
              _safeSetState(() {
                _selectedFiles[fileIndex] = file.copyWith(
                  revisionId: value,
                  revisionCode: selectedOption['name']?.toString(),
                );
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildFileDocumentTypeDropdown(int fileIndex) {
    final file = _selectedFiles[fileIndex];
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: file.documentTypeId,
          hint: Text(
            'Doc Type',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          style: const TextStyle(fontSize: 10, color: Colors.black87),
          items: _documentTypeOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['id']?.toString(),
              child: Text(
                option['name']?.toString() ?? '',
                style: const TextStyle(fontSize: 10),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              final selectedOption = _documentTypeOptions.firstWhere(
                (option) => option['id']?.toString() == value,
                orElse: () => {},
              );
              _safeSetState(() {
                _selectedFiles[fileIndex] = file.copyWith(
                  documentTypeId: value,
                  documentTypeName: selectedOption['name']?.toString(),
                );
              });
            }
          },
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _uploadFiles,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: _isUploading
              ? LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                )
              : const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: _isUploading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ] else ...[
              const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              _isUploading
                  ? 'Uploading...'
                  : 'Upload ${_selectedFiles.length} file(s)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No documents yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first document!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    final fileName = file['fileName']?.toString() ?? 'Unknown File';
    final fileSize = file['fileSize'] ?? 0;
    final fileType = file['fileType']?.toString() ?? '';
    final createdDate = file['createdDate']?.toString();
    final revisionCode = file['revisionCode']?.toString();
    final documentTypeName = file['documentTypeName']?.toString();
    final revisionName = file['revisionName']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Row(
          children: [
            // File Icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _getFileTypeColor(fileType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileTypeIcon(fileType),
                color: _getFileTypeColor(fileType),
                size: 22,
              ),
            ),

            const SizedBox(width: 5),

            // File Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatFileSize(fileSize),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (createdDate != null) ...[
                        Text(
                          ' • ',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        Text(
                          _formatUploadDate(createdDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Show revision and document type info if available
                  if (revisionCode != null ||
                      documentTypeName != null ||
                      revisionName != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (revisionCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              'Rev: $revisionCode',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (revisionName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              'Revision: $revisionName',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (documentTypeName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Text(
                              'Type: $documentTypeName',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFileActionButton(
                  icon: Icons.download,
                  color: Colors.blue,
                  onTap: () => _downloadFile(file),
                ),
                const SizedBox(width: 8),
                _buildFileActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: () => _deleteFile(file),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType, {String? fileName}) {
    final category = _classifyMime(_resolveMime(fileType, fileName));
    switch (category) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'text':
        return Icons.article_outlined;
      case 'word':
        return Icons.description;
      case 'excel':
        return Icons.grid_on;
      case 'powerpoint':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileType, {String? fileName}) {
    final category = _classifyMime(_resolveMime(fileType, fileName));
    switch (category) {
      case 'image':
        return Colors.green;
      case 'pdf':
        return Colors.red;
      case 'text':
        return Colors.indigo;
      case 'word':
        return Colors.blue;
      case 'excel':
        return Colors.teal;
      case 'powerpoint':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatUploadDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }
}
