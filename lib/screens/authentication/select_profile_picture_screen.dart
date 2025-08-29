// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:bus_kahan_hay/core/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class SelectProfilePictureScreen extends StatefulWidget {
//   const SelectProfilePictureScreen({super.key});

//   @override
//   State<SelectProfilePictureScreen> createState() =>
//       _SelectProfilePictureScreenState();
// }

// class _SelectProfilePictureScreenState
//     extends State<SelectProfilePictureScreen> {
//   File? _imageFile;
//   String? _imageUrl;
//   bool _isUploading = false;
//   double _uploadProgress = 0;
//   bool _hasError = false;

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? pickedFile = await picker.pickImage(
//         source: source,
//         imageQuality: 85,
//         maxWidth: 800,
//       );

//       if (pickedFile != null) {
//         setState(() {
//           _imageFile = File(pickedFile.path);
//           _hasError = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error selecting image: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _uploadToImage() async {
//     if (_imageFile == null) return;

//     setState(() {
//       _isUploading = true;
//       _uploadProgress = 0;
//       _hasError = false; // Reset error state when upload starts
//     });

//     try {
//       final url = Uri.parse('https://api.cloudinary.com/v1_1/diu1cxyph/upload');
//       final request = http.MultipartRequest('POST', url)
//         ..fields['upload_preset'] = 'profiles'
//         ..files.add(
//           await http.MultipartFile.fromPath('file', _imageFile!.path),
//         );

//       // Create a completer to handle the response
//       final completer = Completer<http.Response>();
//       final responseStream = await request.send();
//       final totalBytes = responseStream.contentLength ?? 0;
//       int receivedBytes = 0;

//       // Collect the response data
//       final chunks = <List<int>>[];
//       responseStream.stream.listen(
//         (List<int> chunk) {
//           // Update progress
//           receivedBytes += chunk.length;
//           if (mounted) {
//             setState(() {
//               _uploadProgress = totalBytes > 0 ? receivedBytes / totalBytes : 0;
//             });
//           }
//           // Collect chunks for the response
//           chunks.add(chunk);
//         },
//         onDone: () async {
//           // Combine all chunks into a single response
//           final response = http.Response.bytes(
//             chunks.expand((x) => x).toList(),
//             responseStream.statusCode,
//             request: responseStream.request,
//             headers: responseStream.headers,
//             isRedirect: responseStream.isRedirect,
//             persistentConnection: responseStream.persistentConnection,
//             reasonPhrase: responseStream.reasonPhrase,
//           );
//           completer.complete(response);
//         },
//         onError: (e) {
//           completer.completeError(e);
//         },
//       );

//       // Wait for the response
//       final response = await completer.future.timeout(
//         const Duration(seconds: 30),
//       );

//       if (response.statusCode == 200) {
//         final jsonMap = jsonDecode(response.body);
//         if (mounted) {
//           setState(() {
//             _imageUrl = jsonMap['secure_url'] ?? jsonMap['url'];
//           });
//         }

//         // Save image URL to local storage
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('profileImageUrl', _imageUrl!);

//         // Redirect to /home
//         if (mounted) {
//           Navigator.pushReplacementNamed(context, '/home');
//         }
//       } else {
//         throw Exception('Upload failed with status: ${response.statusCode}');
//       }
//     } on TimeoutException {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Upload timed out. Please try again.')),
//         );
//       }
//       setState(() {
//         _hasError = true; // Show error on failure
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Upload failed: ${e.toString()}')),
//         );
//       }
//       setState(() {
//         _hasError = true; // Show error on failure
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isUploading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double avatarSize = 130;

//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           // foregroundColor: AppColors.white,
//           title: const Text(
//             'Upload Profile Picture',

//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),
//           backgroundColor: AppColors.green,
//           iconTheme: IconThemeData(color: AppColors.white),
//         ),
//         body: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Center(
//                   child: _imageFile != null
//                       ? CircleAvatar(
//                           radius: avatarSize / 2,
//                           backgroundImage: FileImage(_imageFile!),
//                         )
//                       : CircleAvatar(
//                           radius: avatarSize / 2,
//                           backgroundColor: Colors.grey[300],
//                           child: const Icon(
//                             Icons.person,
//                             size: 60,
//                             color: Colors.grey,
//                           ),
//                         ),
//                 ),
//                 const SizedBox(height: 24),
//                 // Upload progress indicator
//                 _hasError
//                     ? AnimatedOpacity(
//                         opacity: _hasError ? 1.0 : 0.0,
//                         duration: const Duration(milliseconds: 500),
//                         child: Container(
//                           width: double.infinity,
//                           height: 4,
//                           color: Colors.red,
//                           child: const Center(
//                             child: Text(
//                               'Error occurred!',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ),
//                       )
//                     : LinearProgressIndicator(
//                         value: _uploadProgress,
//                         backgroundColor: Colors.grey[300],
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           AppColors.green,
//                         ),
//                       ),
//                 const SizedBox(height: 20),
//                 ElevatedButton.icon(
//                   onPressed: _isUploading
//                       ? null
//                       : () => _pickImage(ImageSource.camera),
//                   icon: const Icon(Icons.camera_alt),
//                   label: const Text(
//                     'Take a Picture',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.green,
//                     minimumSize: const Size.fromHeight(50),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton.icon(
//                   onPressed: _isUploading
//                       ? null
//                       : () => _pickImage(ImageSource.gallery),
//                   icon: const Icon(Icons.photo_library),
//                   label: const Text(
//                     'Choose from Gallery',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.green,
//                     minimumSize: const Size.fromHeight(50),
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 ElevatedButton.icon(
//                   onPressed: _imageFile == null || _isUploading
//                       ? null
//                       : _uploadToImage,
//                   icon: _isUploading
//                       ? SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Icon(Icons.save),
//                   label: Text(
//                     _isUploading ? 'Uploading...' : 'Save and Continue',
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.green,
//                     minimumSize: const Size.fromHeight(50),
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pushReplacementNamed(context, '/home');
//                   },
//                   child: const Text('Skip for now'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

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
    final double avatarSize = 130;
    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.green,
        body: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Upload Profile Picture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the row
                ],
              ),
            ),

            // Form Section
            Expanded(
              child: Container(
                width: width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 30),

                      // Profile Picture Preview
                      Center(
                        child: _imageFile != null
                            ? CircleAvatar(
                                radius: avatarSize / 2,
                                backgroundImage: FileImage(_imageFile!),
                              )
                            : CircleAvatar(
                                radius: avatarSize / 2,
                                backgroundColor: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                      ),

                      const SizedBox(height: 30),

                      // Upload progress indicator
                      _hasError
                          ? Container(
                              width: double.infinity,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Center(
                                child: Text(
                                  'Error occurred!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          : LinearProgressIndicator(
                              value: _uploadProgress,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.green,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),

                      const SizedBox(height: 30),

                      // Camera Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading
                              ? null
                              : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 24),
                          label: const Text(
                            'Take a Picture',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Gallery Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 24),
                          label: const Text(
                            'Choose from Gallery',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _imageFile == null || _isUploading
                              ? null
                              : _uploadToImage,
                          icon: _isUploading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save, size: 24),
                          label: Text(
                            _isUploading ? 'Uploading...' : 'Save and Continue',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Skip Button
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
