export 'landlordHome.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker_web/image_picker_web.dart';

class LandlordHome extends StatelessWidget {
  const LandlordHome({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FindMyPad - Landlord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('properties')
            .where('landlordId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return PropertyListingCard(
                  title: data['name'],
                  location: data['location'],
                  price: data['price'].toString(),
                  propertyId: doc.id,
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPropertyModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPropertyModal(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    String? base64Image;
    List<String> roomImages = [];

    // Create a state holder for the UI update
    StateSetter? modalSetState;

    Future<String?> pickAndCompressImage() async {
      try {
        if (kIsWeb) {
          final media = await ImagePickerWeb.getImageInfo();
          if (media != null) {
            final bytes = media.data;
            if (bytes != null) {
              return base64Encode(bytes);
            }
          }
        } else {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(source: ImageSource.gallery);

          if (image == null) return null;

          final File imageFile = File(image.path);
          final List<int>? compressedImage = await FlutterImageCompress.compressWithFile(
            imageFile.path,
            minHeight: 600,
            minWidth: 800,
            quality: 70,
          );

          if (compressedImage != null) {
            return base64Encode(compressedImage);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error picking image: $e')),
          );
        }
      }
      return null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          modalSetState = setState;
          return Dialog(
            // Set a maximum width for the dialog
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add New Property',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (base64Image != null) ...[
                        Container(
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(base64Image!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed: () async {
                          final newImage = await pickAndCompressImage();
                          if (newImage != null) {
                            modalSetState?.call(() {
                              base64Image = newImage;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Image uploaded successfully')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: Text(base64Image == null ? 'Upload Image' : 'Change Image'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Room Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (roomImages.isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: roomImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 160,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(roomImages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 12,
                                    top: 4,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        modalSetState?.call(() {
                                          roomImages.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final newImage = await pickAndCompressImage();
                          if (newImage != null) {
                            modalSetState?.call(() {
                              roomImages.add(newImage);
                            });
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Room Photo'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Property Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Rent',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                if (base64Image == null) {
                                  throw Exception('Please upload an image');
                                }

                                final userId = FirebaseAuth.instance.currentUser?.uid;
                                await FirebaseFirestore.instance.collection('properties').add({
                                  'name': nameController.text,
                                  'location': locationController.text,
                                  'price': double.parse(priceController.text),
                                  'description': descriptionController.text,
                                  'landlordId': userId,
                                  'imageData': base64Image,
                                  'roomImages': roomImages,
                                  'status': 'pending',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Property added successfully')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                            child: const Text('Add Property'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PropertyListingCard extends StatelessWidget {
  final String title;
  final String location;
  final String price;
  final String propertyId;

  const PropertyListingCard({
    super.key,
    required this.title,
    required this.location,
    required this.price,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('properties')
                .doc(propertyId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final imageData = data['imageData'] as String?;

                if (imageData != null) {
                  return Image.memory(
                    base64Decode(imageData),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                }
              }
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: Text('No image available')),
              );
            },
          ),
          ListTile(
            title: Text(title),
            subtitle: Text('$location\n₱$price/month'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: const Text('Edit Property'),
                  onTap: () => _editProperty(context),
                ),
                PopupMenuItem(
                  value: 'view_applicants',
                  child: const Text('View Applicants'),
                  onTap: () => _viewApplicants(context),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Text('Delete'),
                  onTap: () => _showDeleteConfirmation(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProperty(BuildContext context) async {
    final propertyDoc = await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .get();

    if (!context.mounted) return;

    final data = propertyDoc.data()!;
    final nameController = TextEditingController(text: data['name']);
    final locationController = TextEditingController(text: data['location']);
    final priceController = TextEditingController(text: data['price'].toString());
    final descriptionController = TextEditingController(text: data['description']);
    String? base64Image = data['imageData'];
    List<String> roomImages = List<String>.from(data['roomImages'] ?? []);

    Future<String?> pickAndCompressImage() async {
      try {
        if (kIsWeb) {
          final media = await ImagePickerWeb.getImageInfo();
          if (media != null) {
            final bytes = media.data;
            if (bytes != null) {
              return base64Encode(bytes);
            }
          }
        } else {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(source: ImageSource.gallery);

          if (image == null) return null;

          final File imageFile = File(image.path);
          final List<int>? compressedImage = await FlutterImageCompress.compressWithFile(
            imageFile.path,
            minHeight: 600,
            minWidth: 800,
            quality: 70,
          );

          if (compressedImage != null) {
            base64Image = base64Encode(compressedImage);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image updated successfully')),
              );
            }
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating image: $e')),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Property',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (base64Image != null) ...[
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(base64Image!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: () async {
                        await pickAndCompressImage();
                        setState(() {});
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Change Image'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Room Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (roomImages.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: roomImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 160,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(roomImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 12,
                                  top: 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        roomImages.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final newImage = await pickAndCompressImage();
                        if (newImage != null) {
                          setState(() {
                            roomImages.add(newImage);
                          });
                        }
                      },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Room Photo'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Property Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Rent',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(propertyId)
                                  .update({
                                'name': nameController.text,
                                'location': locationController.text,
                                'price': double.parse(priceController.text),
                                'description': descriptionController.text,
                                'imageData': base64Image,
                                'roomImages': roomImages,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Property updated successfully'),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text('Are you sure you want to delete this property? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _deleteProperty(context);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Property deleted successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting property: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .delete();

    final applications = await FirebaseFirestore.instance
        .collection('applications')
        .where('propertyId', isEqualTo: propertyId)
        .get();

    for (var doc in applications.docs) {
      await doc.reference.delete();
    }
  }

  void _viewApplicants(BuildContext context) async {
    try {
      // Check if the property exists first
      final propertyDoc = await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .get();

      if (!propertyDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Property no longer exists'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApplicantsScreen(
              propertyId: propertyId,
              propertyName: title, // Pass property name for reference
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading applicants: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ApplicantsScreen extends StatelessWidget {
  final String propertyId;
  final String propertyName;

  const ApplicantsScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  void _showApplicantDetails(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Applicant Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Full Name'),
                subtitle: Text('${data['firstName']} ${data['lastName']}'),
                leading: const Icon(Icons.person),
              ),
              ListTile(
                title: const Text('Email'),
                subtitle: Text(data['email'] ?? 'N/A'),
                leading: const Icon(Icons.email),
              ),
              ListTile(
                title: const Text('Phone'),
                subtitle: Text(data['phone'] ?? 'N/A'),
                leading: const Icon(Icons.phone),
              ),
              ListTile(
                title: const Text('Message'),
                subtitle: Text(data['message'] ?? 'No message'),
                leading: const Icon(Icons.message),
              ),
              ListTile(
                title: const Text('Status'),
                subtitle: Text(data['status'] ?? 'Pending'),
                leading: const Icon(Icons.info),
              ),
              ListTile(
                title: const Text('Applied On'),
                subtitle: Text(
                  data['appliedAt'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          data['appliedAt'].millisecondsSinceEpoch,
                        ).toString()
                      : 'N/A',
                ),
                leading: const Icon(Icons.calendar_today),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (data['status'] == 'pending')
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('applications')
                      .doc(doc.id)
                      .update({
                    'status': 'approved',
                    'approvedAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Application approved successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error approving application: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Approve'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Applicants - $propertyName'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('propertyId', isEqualTo: propertyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading applicants\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading applicants...'),
                ],
              ),
            );
          }

          final applications = snapshot.data?.docs ?? [];

          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No applicants yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Applications will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final data = applications[index].data() as Map<String, dynamic>;
              final applicationId = applications[index].id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    '${data['firstName']?[0] ?? ''}${data['lastName']?[0] ?? ''}'.toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '${data['firstName'] ?? 'Unknown'} ${data['lastName'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(data['email'] ?? 'No email provided'),
                trailing: _buildStatusChip(data['status'] ?? 'pending'),
                onTap: () => _showApplicantDetails(context, applications[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        break;
      case 'pending':
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.capitalize(),
        style: TextStyle(color: textColor),
      ),
    );
  }
}

// Add this extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}