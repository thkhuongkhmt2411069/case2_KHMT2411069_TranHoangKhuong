
import 'package:flutter/material.dart';
import 'api_service.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onLogout;

  const DashboardPage({
    super.key,
    required this.onLogout,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<dynamic> tasks = [];
  List<dynamic> notifications = [];
  Map<String, dynamic> statistics = {};

  String userName = '';
  String? userId;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  // Tải dữ liệu
  Future<void> loadAll() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait<Object?>([
        ApiService.getTasks(),
        ApiService.getNotifications().catchError((_) => <dynamic>[]),
        ApiService.getStatistics().catchError((_) => <String, dynamic>{}),
        ApiService.getUserName().catchError((_) => null),
        ApiService.getUserId().catchError((_) => null),
      ]);

      if (!mounted) return;

      setState(() {
        tasks = results[0] as List<dynamic>;
        notifications = results[1] as List<dynamic>;
        statistics = results[2] as Map<String, dynamic>;
        userName = results[3] as String? ?? '';
        userId = results[4] as String?;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  // Lấy số liệu thống kê
  int statValue(String key, String status) {
    final value = statistics[key];

    if (value is num) {
      return value.toInt();
    }

    if (key == 'total') {
      return tasks.length;
    }

    return tasks.where((task) {
      return task['status'] == status;
    }).length;
  }

  // Lấy ID người dùng
  String? getId(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      return (value['_id'] ?? value['id'])?.toString();
    }

    return value.toString();
  }

  // Kiểm tra chủ sở hữu
  bool isOwner(dynamic task) {
    return getId(task['createdBy']) == userId;
  }

  // Kiểm tra quyền Editor
  bool isEditor(dynamic task) {
    final sharedWith = task['sharedWith'];

    if (sharedWith is! List) return false;

    return sharedWith.any((item) {
      if (item is! Map) return false;

      return getId(item['user']) == userId &&
          item['role'] == 'editor';
    });
  }

  // Kiểm tra quyền chỉnh sửa
  bool canEdit(dynamic task) {
    return isOwner(task) || isEditor(task);
  }

  // Số thông báo chưa đọc
  int get unreadCount {
    return notifications.where((item) {
      return item is Map && item['isRead'] != true;
    }).length;
  }

  // Thêm hoặc chỉnh sửa công việc
  Future<void> showTaskDialog({dynamic task}) async {
    final isEditing = task != null;

    final titleController = TextEditingController(
      text: isEditing ? task['title'] ?? '' : '',
    );

    final descriptionController = TextEditingController(
      text: isEditing ? task['description'] ?? '' : '',
    );

    String selectedStatus =
        isEditing ? task['status'] ?? 'todo' : 'todo';

    bool isSaving = false;

    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Chỉnh sửa công việc' : 'Thêm công việc',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề công việc',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'todo',
                            child: Text('Cần làm'),
                          ),
                          DropdownMenuItem(
                            value: 'in_progress',
                            child: Text('Đang làm'),
                          ),
                          DropdownMenuItem(
                            value: 'done',
                            child: Text('Hoàn thành'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final description =
                              descriptionController.text.trim();

                          if (title.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập tiêu đề'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            if (isEditing) {
                              await ApiService.updateTask(
                                task['_id'].toString(),
                                title,
                                description,
                                selectedStatus,
                              );
                            } else {
                              await ApiService.createTask(
                                title,
                                description,
                              );
                            }

                            if (!mounted || !dialogContext.mounted) return;

                            Navigator.pop(dialogContext);
                            await loadAll();

                            if (!mounted) return;

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Cập nhật thành công'
                                      : 'Thêm công việc thành công',
                                ),
                              ),
                            );
                          } catch (error) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            messenger.showSnackBar(
                              SnackBar(content: Text('Lỗi: $error')),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEditing ? 'Cập nhật' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
  }

  // Xóa công việc
  Future<void> deleteTask(dynamic task) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc muốn xóa "${task['title']}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteTask(task['_id'].toString());

      await loadAll();

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Xóa công việc thành công'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Lỗi: $error')),
      );
    }
  }

  // Giao công việc
  Future<void> showAssignDialog(dynamic task) async {
    final emailController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Giao công việc'),
              content: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email thành viên',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final email = emailController.text.trim();

                          if (email.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập email'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await ApiService.assignTask(
                              task['_id'].toString(),
                              email,
                            );

                            if (!mounted || !dialogContext.mounted) return;

                            Navigator.pop(dialogContext);
                            await loadAll();

                            if (!mounted) return;

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Giao công việc thành công'),
                              ),
                            );
                          } catch (error) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            messenger.showSnackBar(
                              SnackBar(content: Text('Lỗi: $error')),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Giao việc'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  // Chia sẻ công việc
  Future<void> showShareDialog(dynamic task) async {
    final emailController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    String selectedRole = 'viewer';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Chia sẻ công việc'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email thành viên',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Quyền truy cập',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'viewer',
                        child: Text('Viewer - Chỉ xem'),
                      ),
                      DropdownMenuItem(
                        value: 'editor',
                        child: Text('Editor - Được chỉnh sửa'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final email = emailController.text.trim();

                          if (email.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập email'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await ApiService.shareTask(
                              task['_id'].toString(),
                              email,
                              selectedRole,
                            );

                            if (!mounted || !dialogContext.mounted) return;

                            Navigator.pop(dialogContext);
                            await loadAll();

                            if (!mounted) return;

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Chia sẻ thành công'),
                              ),
                            );
                          } catch (error) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            messenger.showSnackBar(
                              SnackBar(content: Text('Lỗi: $error')),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Chia sẻ'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  // Hiển thị thông báo
  Future<void> openNotifications() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await ApiService.getNotifications();

      if (!mounted) return;

      setState(() {
        notifications = result;
      });

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    const Expanded(
                      child: Text('Thông báo'),
                    ),
                    TextButton(
                      onPressed: notifications.isEmpty || unreadCount == 0
                          ? null
                          : () async {
                              try {
                                await ApiService.markAllNotificationsRead();
                                await loadAll();

                                if (!mounted) return;

                                setDialogState(() {});
                              } catch (error) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Lỗi: $error')),
                                );
                              }
                            },
                      child: const Text('Đọc tất cả'),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 420,
                  child: notifications.isEmpty
                      ? const Text('Bạn chưa có thông báo nào')
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) {
                            return const Divider(height: 1);
                          },
                          itemBuilder: (context, index) {
                            final item = notifications[index];
                            final isRead = item['isRead'] == true;

                            return ListTile(
                              leading: Icon(
                                isRead
                                    ? Icons.notifications_none
                                    : Icons.notifications_active,
                                color: isRead ? Colors.grey : Colors.blue,
                              ),
                              title: Text(
                                item['message']?.toString() ??
                                    'Bạn có thông báo mới',
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                isRead ? 'Đã đọc' : 'Chưa đọc',
                              ),
                              onTap: isRead
                                  ? null
                                  : () async {
                                      try {
                                        await ApiService.markNotificationRead(
                                          item['_id'].toString(),
                                        );

                                        await loadAll();

                                        if (!mounted) return;

                                        setDialogState(() {});
                                      } catch (error) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi: $error'),
                                          ),
                                        );
                                      }
                                    },
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể tải thông báo: $error'),
        ),
      );
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiService.logout();

      if (!mounted) return;

      widget.onLogout();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng xuất: $error')),
      );
    }
  }

  // Tên trạng thái
  String statusLabel(String? status) {
    switch (status) {
      case 'todo':
        return 'Cần làm';
      case 'in_progress':
        return 'Đang làm';
      case 'done':
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  // Màu trạng thái
  Color statusColor(String? status) {
    switch (status) {
      case 'todo':
        return Colors.orange;
      case 'in_progress':
        return Colors.purple;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Thẻ thống kê
  Widget statCard(
    String title,
    int value,
    Color color,
    IconData icon,
  ) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(title),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Thẻ công việc
  Widget taskCard(dynamic task) {
    final owner = isOwner(task);
    final editable = canEdit(task);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task['title']?.toString() ?? 'Không có tiêu đề',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    statusLabel(task['status']?.toString()),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: statusColor(
                    task['status']?.toString(),
                  ).withValues(alpha: 0.15),
                ),
              ],
            ),
            if ((task['description'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(task['description'].toString()),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                if (editable)
                  TextButton.icon(
                    onPressed: () => showTaskDialog(task: task),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Sửa'),
                  ),
                if (owner)
                  TextButton.icon(
                    onPressed: () => showAssignDialog(task),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Giao việc'),
                  ),
                if (owner)
                  TextButton.icon(
                    onPressed: () => showShareDialog(task),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Chia sẻ'),
                  ),
                if (owner)
                  TextButton.icon(
                    onPressed: () => deleteTask(task),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Xóa'),
                  ),
                if (!owner && !editable)
                  const Text(
                    'Quyền chỉ xem',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Task Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            onPressed: openNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (unreadCount > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.red,
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: loadAll,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm công việc'),
      ),
      body: RefreshIndicator(
        onRefresh: loadAll,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              userName.isEmpty ? 'Xin chào!' : 'Xin chào, $userName!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tổng quan công việc',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Center(
                child: Column(
                  children: [
                    Text(errorMessage!),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: loadAll,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  statCard(
                    'Tổng công việc',
                    statValue('total', ''),
                    Colors.blue,
                    Icons.assignment,
                  ),
                  statCard(
                    'Cần làm',
                    statValue('todo', 'todo'),
                    Colors.orange,
                    Icons.pending_actions,
                  ),
                  statCard(
                    'Đang làm',
                    statValue('inProgress', 'in_progress'),
                    Colors.purple,
                    Icons.autorenew,
                  ),
                  statCard(
                    'Hoàn thành',
                    statValue('done', 'done'),
                    Colors.green,
                    Icons.check_circle_outline,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Danh sách công việc',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Bạn chưa có công việc nào'),
                    ),
                  ),
                )
              else
                ...tasks.map(taskCard),
            ],
          ],
        ),
      ),
    );
  }
}
