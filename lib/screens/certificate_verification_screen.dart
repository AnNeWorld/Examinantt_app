import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';

/// Matches https://www.examinantt.com/verify/:certificateId
/// Queries Firestore collection 'courseCertificates'
class CertificateVerificationScreen extends StatefulWidget {
  final String? initialCertificateId;

  const CertificateVerificationScreen({
    super.key,
    this.initialCertificateId,
  });

  @override
  State<CertificateVerificationScreen> createState() => _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState extends State<CertificateVerificationScreen> {
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _certificateData;
  String? _errorMessage;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCertificateId != null && widget.initialCertificateId!.trim().isNotEmpty) {
      _idController.text = widget.initialCertificateId!.trim();
      _verifyCertificate(widget.initialCertificateId!.trim());
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _verifyCertificate(String certId) async {
    final cleanId = certId.trim();
    if (cleanId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid certificate ID';
        _certificateData = null;
        _searched = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searched = true;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('courseCertificates').doc(cleanId);
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data() != null) {
        setState(() {
          _certificateData = {
            'id': docSnap.id,
            ...docSnap.data()!,
          };
          _isLoading = false;
        });
        return;
      }

      // Try searching by certificateId field or query if ID was case-insensitive
      final querySnap = await FirebaseFirestore.instance
          .collection('courseCertificates')
          .where('id', isEqualTo: cleanId)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        final d = querySnap.docs.first;
        setState(() {
          _certificateData = {
            'id': d.id,
            ...d.data(),
          };
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _certificateData = null;
        _errorMessage = 'No verified certificate found for "$cleanId". Please verify the Certificate ID and try again.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _certificateData = null;
        _errorMessage = 'Verification error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF070D1E) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF0B152B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF17254E) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF070D1E) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Certificate Verification',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'OFFICIAL EXAMINANTT PORTAL',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'Verify Certificate Authenticity',
              style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the Certificate ID printed on the certificate to check official verification status.',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _idController,
                      style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'e.g. EXM-CERT-123456',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF38BDF8), size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onSubmitted: _verifyCertificate,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _verifyCertificate(_idController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0070F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Result Display
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0070F3)),
                ),
              )
            else if (_certificateData != null)
              _buildVerifiedCard(_certificateData!, isDark, cardBg, borderColor, textColor)
            else if (_errorMessage != null)
              _buildErrorCard(_errorMessage!, isDark, cardBg, borderColor)
            else if (!_searched)
              _buildHelpGuide(isDark, cardBg, borderColor, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedCard(
    Map<String, dynamic> data,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
  ) {
    final certId = data['id'] ?? data['certificateId'] ?? '';
    final studentName = data['userName'] ?? data['studentName'] ?? data['recipientName'] ?? 'Student';
    final courseTitle = data['courseTitle'] ?? data['courseName'] ?? data['batchTitle'] ?? 'Examinantt Curriculum';
    final status = (data['status'] ?? 'valid').toString().toUpperCase();
    final isValid = status == 'VALID' || status == 'VERIFIED' || status == 'ACTIVE';

    DateTime? issueDate;
    if (data['issuedAt'] is Timestamp) {
      issueDate = (data['issuedAt'] as Timestamp).toDate();
    } else if (data['completionDate'] is Timestamp) {
      issueDate = (data['completionDate'] as Timestamp).toDate();
    }

    final dateStr = issueDate != null ? DateFormat('dd MMMM yyyy').format(issueDate) : 'Official Archive';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isValid ? const Color(0xFF10B981).withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isValid ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isValid ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isValid ? Icons.verified_rounded : Icons.cancel_rounded, color: isValid ? const Color(0xFF10B981) : Colors.redAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  isValid ? 'VERIFIED OFFICIAL CERTIFICATE' : 'REVOKED / INVALID CERTIFICATE',
                  style: TextStyle(
                    color: isValid ? const Color(0xFF10B981) : Colors.redAccent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 64),
          const SizedBox(height: 8),

          Text(
            'Certificate of Completion',
            style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: $certId',
            style: const TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          Text(
            'This certifies that',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            studentName,
            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 22, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'has successfully completed the curriculum for',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            courseTitle,
            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCertMetaCol('Issue Date', dateStr, isDark, textColor),
              _buildCertMetaCol('Status', status, isDark, isValid ? const Color(0xFF10B981) : Colors.redAccent),
              _buildCertMetaCol('Issuer', 'Examinantt', isDark, textColor),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildCertMetaCol(String label, String value, bool isDark, Color valColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 9.5)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: valColor, fontSize: 11.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildErrorCard(String error, bool isDark, Color cardBg, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Verification Failed',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpGuide(bool isDark, Color cardBg, Color borderColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              Text('How to find your Certificate ID?', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• Check the bottom-left corner of your digital certificate.\n• Certificate format looks like: EXM-CERT-123456\n• Issued certificates are also accessible in your profile under "My Learning".',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
