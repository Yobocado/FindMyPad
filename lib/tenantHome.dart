import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

export 'tenantHome.dart';

class TenantHome extends StatelessWidget {
  const TenantHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FindMyPad - Tenant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApplicationsScreen(),
                ),
              );
            },
          ),
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
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
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
                  Text('Loading properties...'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined, 
                    size: 60, 
                    color: Colors.grey[400]
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No properties available yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new listings',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return PropertyCard(
                image: data['imageData'] ?? '',
                title: data['name'] ?? 'Untitled Property',
                price: '₱${data['price']}/month',
                description: data['description'] ?? 'No description available',
                propertyId: doc.id,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final String image;
  final String title;
  final String price;
  final String description;
  final String propertyId;

  const PropertyCard({
    super.key,
    required this.image,
    required this.title,
    required this.price,
    required this.description,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyDetails(propertyId: propertyId),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('properties')
                  .doc(propertyId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Container(
                    height: 200,
                    color: Colors.red[100],
                    child: const Center(
                      child: Text(
                        'Error loading image',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Property no longer available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final imageData = data['imageData'] as String?;
                
                if (imageData != null) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                    child: Image.memory(
                      base64Decode(imageData),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Text('No image available')),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showApplyModal(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyModal(BuildContext context) {
    final messageController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apply for Property'),
          content: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Text('Error loading user information');
              }

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              if (userData == null) {
                return const Text('Please complete your profile first');
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Information:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Name: ${userData['firstName']} ${userData['lastName']}'),
                    Text('Email: ${currentUser?.email}'),
                    Text('Phone: ${userData['contact'] ?? 'Not provided'}'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message to Landlord',
                        hintText: 'Add a short message with your application...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    throw Exception('Please sign in to apply');
                  }

                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .get();

                  if (!userDoc.exists) {
                    throw Exception('Please complete your profile first');
                  }

                  final userData = userDoc.data()!;
                  
                  await FirebaseFirestore.instance.collection('applications').add({
                    'propertyId': propertyId,
                    'tenantId': currentUser.uid,
                    'firstName': userData['firstName'],
                    'lastName': userData['lastName'],
                    'email': currentUser.email,
                    'phone': userData['contact'],
                    'message': messageController.text,
                    'status': 'pending',
                    'appliedAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Application submitted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Submit Application'),
            ),
          ],
        );
      },
    );
  }
}

class PropertyDetails extends StatelessWidget {
  final String propertyId;

  const PropertyDetails({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('properties')
            .doc(propertyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('Property not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Images Carousel
                SizedBox(
                  height: 300,
                  child: PageView(
                    children: [
                      if (data['imageData'] != null)
                        Image.memory(
                          base64Decode(data['imageData']),
                          fit: BoxFit.cover,
                        ),
                      ...(data['roomImages'] as List<dynamic>? ?? []).map(
                        (imageData) => Image.memory(
                          base64Decode(imageData),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),

                // Property Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unnamed Property',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${data['price']}/month',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Location
                      _DetailSection(
                        title: 'Location',
                        content: data['location'] ?? 'Location not specified',
                        icon: Icons.location_on,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _DetailSection(
                        title: 'Description',
                        content: data['description'] ?? 'No description available',
                        icon: Icons.description,
                      ),
                      const SizedBox(height: 24),

                      // Room Photos Grid
                      if ((data['roomImages'] as List<dynamic>?)?.isNotEmpty ?? false) ...[
                        const Text(
                          'Room Photos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: (data['roomImages'] as List<dynamic>).length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _showFullImage(
                                context,
                                data['roomImages'][index],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(data['roomImages'][index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showApplyModal(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Apply for this Property',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Image.memory(
            base64Decode(imageData),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _showApplyModal(BuildContext context) {
    final messageController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apply for Property'),
          content: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Text('Error loading user information');
              }

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              if (userData == null) {
                return const Text('Please complete your profile first');
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Information:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Name: ${userData['firstName']} ${userData['lastName']}'),
                    Text('Email: ${currentUser?.email}'),
                    Text('Phone: ${userData['contact'] ?? 'Not provided'}'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message to Landlord',
                        hintText: 'Add a short message with your application...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    throw Exception('Please sign in to apply');
                  }

                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .get();

                  if (!userDoc.exists) {
                    throw Exception('Please complete your profile first');
                  }

                  final userData = userDoc.data()!;
                  
                  await FirebaseFirestore.instance.collection('applications').add({
                    'propertyId': propertyId,
                    'tenantId': currentUser.uid,
                    'firstName': userData['firstName'],
                    'lastName': userData['lastName'],
                    'email': currentUser.email,
                    'phone': userData['contact'],
                    'message': messageController.text,
                    'status': 'pending',
                    'appliedAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Application submitted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Submit Application'),
            ),
          ],
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _DetailSection({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('tenantId', isEqualTo: currentUser?.uid)
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final applications = snapshot.data?.docs ?? [];

          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, 
                    size: 64, 
                    color: Colors.grey[400]
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No applications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index].data() as Map<String, dynamic>;
              final propertyId = application['propertyId'] as String;
              final appliedAt = application['appliedAt'] as Timestamp?;
              final formattedDate = appliedAt != null 
                  ? DateTime.fromMillisecondsSinceEpoch(
                      appliedAt.millisecondsSinceEpoch)
                      .toString()
                      .split('.')[0]
                  : 'Date not available';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('properties')
                    .doc(propertyId)
                    .get(),
                builder: (context, propertySnapshot) {
                  if (propertySnapshot.hasError) {
                    return Card(
                      child: ListTile(
                        title: const Text('Error loading property'),
                        subtitle: Text('Error: ${propertySnapshot.error}'),
                      ),
                    );
                  }

                  if (propertySnapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: ListTile(
                        title: Text('Loading property details...'),
                        leading: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (!propertySnapshot.hasData || !propertySnapshot.data!.exists) {
                    return Card(
                      child: ListTile(
                        title: const Text('Property Unavailable'),
                        subtitle: Text('Application from: $formattedDate'),
                        trailing: _buildStatusChip(application['status'] ?? 'pending'),
                      ),
                    );
                  }

                  final propertyData = propertySnapshot.data!.data() as Map<String, dynamic>;

                  return Card(
                    child: Column(
                      children: [
                        if (propertyData['imageData'] != null) ...[
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            child: Image.memory(
                              base64Decode(propertyData['imageData']),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.error_outline),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        ListTile(
                          title: Text(propertyData['name'] ?? 'Unknown Property'),
                          subtitle: Text(
                            'Status: ${application['status']?.toUpperCase() ?? 'PENDING'}\n'
                            'Applied on: $formattedDate',
                          ),
                          trailing: application['status'] == 'approved'
                              ? ElevatedButton.icon(
                                  icon: const Icon(Icons.contact_mail),
                                  label: const Text('Contact'),
                                  onPressed: () => _showLandlordContact(
                                    context,
                                    propertyData['landlordId'],
                                  ),
                                )
                              : _buildStatusChip(application['status'] ?? 'pending'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showLandlordContact(BuildContext context, String? landlordId) async {
    if (landlordId == null) return;

    try {
      final landlordDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(landlordId)
          .get();

      if (!context.mounted) return;

      if (!landlordDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Landlord information not found')),
        );
        return;
      }

      final landlordData = landlordDoc.data()!;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Landlord Contact Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text('${landlordData['firstName']} ${landlordData['lastName']}'),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(landlordData['email'] ?? 'No email provided'),
                onTap: () {
                  // Add email launch functionality if needed
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(landlordData['contact'] ?? 'No phone provided'),
                onTap: () {
                  // Add phone call launch functionality if needed
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
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
        status.toUpperCase(),
        style: TextStyle(color: textColor),
      ),
    );
  }
}