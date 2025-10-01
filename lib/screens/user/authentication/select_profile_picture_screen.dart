import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SelectProfilePictureScreen extends StatefulWidget {
  const SelectProfilePictureScreen({super.key});

  @override
  State<SelectProfilePictureScreen> createState() =>
      _SelectProfilePictureScreenState();
}

class _SelectProfilePictureScreenState
    extends State<SelectProfilePictureScreen> {
  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _hasError = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadToImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _hasError = false; // Reset error state when upload starts
    });

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/diu1cxyph/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'profiles'
        ..files.add(
          await http.MultipartFile.fromPath('file', _imageFile!.path),
        );

      // Create a completer to handle the response
      final completer = Completer<http.Response>();
      final responseStream = await request.send();
      final totalBytes = responseStream.contentLength ?? 0;
      int receivedBytes = 0;

      // Collect the response data
      final chunks = <List<int>>[];
      responseStream.stream.listen(
        (List<int> chunk) {
          // Update progress
          receivedBytes += chunk.length;
          if (mounted) {
            setState(() {
              _uploadProgress = totalBytes > 0 ? receivedBytes / totalBytes : 0;
            });
          }
          // Collect chunks for the response
          chunks.add(chunk);
        },
        onDone: () async {
          // Combine all chunks into a single response
          final response = http.Response.bytes(
            chunks.expand((x) => x).toList(),
            responseStream.statusCode,
            request: responseStream.request,
            headers: responseStream.headers,
            isRedirect: responseStream.isRedirect,
            persistentConnection: responseStream.persistentConnection,
            reasonPhrase: responseStream.reasonPhrase,
          );
          completer.complete(response);
        },
        onError: (e) {
          completer.completeError(e);
        },
      );

      // Wait for the response
      final response = await completer.future.timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _imageUrl = jsonMap['secure_url'] ?? jsonMap['url'];
          });
        }

        // Save image URL to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageUrl', _imageUrl!);

        // Redirect to /home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload timed out. Please try again.')),
        );
      }
      setState(() {
        _hasError = true; // Show error on failure
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
      setState(() {
        _hasError = true; // Show error on failure
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = 140;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -height * 0.15,
              right: -width * 0.2,
              child: Container(
                width: width * 0.8,
                height: width * 0.8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.green.withOpacity(0.15),
                      AppColors.green.withOpacity(0.05),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              bottom: -height * 0.1,
              left: -width * 0.3,
              child: Container(
                width: width * 0.9,
                height: width * 0.9,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE1BEE7).withOpacity(0.1),
                      Color(0xFFF8BBD9).withOpacity(0.05),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Column(
              children: [
                // Enhanced Header Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.green, Color(0xFF1E8449)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: // REPLACE WITH THIS:
Center(
  child: Column(
    children: [
      Text(
        'Profile Picture',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Add a photo to personalize your account',
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    ],
  ),
),
                ),

                // Form Section
                Expanded(
                  child: Container(
                    width: width,
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),

                          // Title
                          Text(
                            'Add Your Photo',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.green,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose how you\'d like to add your profile picture',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Profile Picture Preview with enhanced styling
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.green.withOpacity(0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: avatarSize / 2,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : null,
                              child: _imageFile == null
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 60,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Upload Progress Indicator
                          if (_isUploading || _hasError) ...[
                            Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Stack(
                                    children: [
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Container(
                                            width:
                                                constraints.maxWidth *
                                                _uploadProgress,
                                            decoration: BoxDecoration(
                                              gradient: _hasError
                                                  ? LinearGradient(
                                                      colors: [
                                                        Colors.red,
                                                        Colors.redAccent,
                                                      ],
                                                    )
                                                  : LinearGradient(
                                                      colors: [
                                                        AppColors.green,
                                                        Color(0xFF1E8449),
                                                      ],
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _hasError
                                      ? 'Upload failed. Please try again.'
                                      : 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: _hasError
                                        ? Colors.red
                                        : AppColors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ],

                          // Camera Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.green,
                                width: 2,
                              ),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isUploading
                                  ? null
                                  : () => _pickImage(ImageSource.camera),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Take Photo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Gallery Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            margin: EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.green,
                                width: 2,
                              ),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isUploading
                                  ? null
                                  : () => _pickImage(ImageSource.gallery),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library_rounded, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Choose from Gallery',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Save Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.green.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _imageFile == null || _isUploading
                                  ? null
                                  : _uploadToImage,
                              child: _isUploading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 24,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Save and Continue',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // Skip Button
                          TextButton(
                            onPressed: _isUploading
                                ? null
                                : () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/home',
                                    );
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Skip for now',
                              style: TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
