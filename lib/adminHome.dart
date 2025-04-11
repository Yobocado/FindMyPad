import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FindMyPad - Admin'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Pending Properties'),
              Tab(text: 'Approved Properties'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _UsersTab(),
            _PendingPropertiesTab(),
            _ApprovedPropertiesTab(),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final userData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final userId = snapshot.data!.docs[index].id;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('${userData['firstName']} ${userData['lastName']}'),
                subtitle: Text(
                  '${userData['email']}\nRole: ${userData['role']}',
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Delete User'),
                      onTap: () async {
                        try {
                          // Delete from Authentication
                          await FirebaseAuth.instance.currentUser?.delete();
                          // Delete from Firestore
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .delete();
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User deleted successfully')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PendingPropertiesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No pending properties'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final propertyData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final propertyId = snapshot.data!.docs[index].id;

            return Card(
              margin: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPropertyDetails(
                      propertyId: propertyId,
                      isPending: true,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    if (propertyData['imageData'] != null)
                      Image.memory(
                        base64Decode(propertyData['imageData']),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ListTile(
                      title: Text(propertyData['name']),
                      subtitle: Text(
                        '${propertyData['location']}\n₱${propertyData['price']}/month',
                      ),
                    ),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(propertyId)
                                  .delete();
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Property rejected')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Reject'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(propertyId)
                                  .update({
                                'status': 'approved',
                                'approvedAt': FieldValue.serverTimestamp(),
                              });
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Property approved')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ApprovedPropertiesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final propertyData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final propertyId = snapshot.data!.docs[index].id;

            return Card(
              margin: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPropertyDetails(
                      propertyId: propertyId,
                    ),
                  ),
                ),
                child: ListTile(
                  title: Text(propertyData['name']),
                  subtitle: Text(
                    '${propertyData['location']}\n₱${propertyData['price']}/month',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('properties')
                            .doc(propertyId)
                            .delete();
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Property deleted')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            );
          },
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
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

class AdminPropertyDetails extends StatelessWidget {
  final String propertyId;
  final bool isPending;

  const AdminPropertyDetails({
    super.key, 
    required this.propertyId,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        actions: [
          if (isPending) ...[
            TextButton.icon(
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('Reject', style: TextStyle(color: Colors.white)),
              onPressed: () => _handleReject(context),
            ),
            TextButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Approve', style: TextStyle(color: Colors.white)),
              onPressed: () => _handleApprove(context),
            ),
          ],
        ],
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
                        GestureDetector(
                          onTap: () => _showFullImage(context, data['imageData']),
                          child: Image.memory(
                            base64Decode(data['imageData']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ...(data['roomImages'] as List<dynamic>? ?? []).map(
                        (imageData) => GestureDetector(
                          onTap: () => _showFullImage(context, imageData),
                          child: Image.memory(
                            base64Decode(imageData),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Landlord Information
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(data['landlordId'])
                            .get(),
                        builder: (context, landlordSnapshot) {
                          if (landlordSnapshot.hasData) {
                            final landlordData = landlordSnapshot.data!.data() as Map<String, dynamic>?;
                            return _DetailSection(
                              title: 'Landlord',
                              content: landlordData != null 
                                  ? '${landlordData['firstName']} ${landlordData['lastName']}\n'
                                    'Email: ${landlordData['email']}\n'
                                    'Contact: ${landlordData['contact'] ?? 'Not provided'}'
                                  : 'Landlord information not available',
                              icon: Icons.person,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 16),

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
                      
                      _DetailSection(
                        title: 'Location',
                        content: data['location'] ?? 'Location not specified',
                        icon: Icons.location_on,
                      ),
                      const SizedBox(height: 16),

                      _DetailSection(
                        title: 'Description',
                        content: data['description'] ?? 'No description available',
                        icon: Icons.description,
                      ),
                      const SizedBox(height: 24),

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

  Future<void> _handleApprove(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property approved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .delete();
          
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}