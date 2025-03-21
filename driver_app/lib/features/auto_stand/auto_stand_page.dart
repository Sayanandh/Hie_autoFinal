import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auto_stand_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/loading_widget.dart';

class AutoStandPage extends StatefulWidget {
  const AutoStandPage({Key? key}) : super(key: key);

  @override
  State<AutoStandPage> createState() => _AutoStandPageState();
}

class _AutoStandPageState extends State<AutoStandPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!_isSearching) {
      setState(() => _isSearching = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final provider = context.read<AutoStandProvider>();
          provider.searchAutoStands(_searchController.text);
          setState(() => _isSearching = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Stands'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search auto stands...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: Consumer<AutoStandProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingWidget();
                }

                if (provider.error != null) {
                  return CustomErrorWidget(
                    error: provider.error!,
                    onRetry: () => provider.searchAutoStands(_searchController.text),
                  );
                }

                if (provider.nearbyStands.isEmpty) {
                  return const Center(
                    child: Text('No auto stands found'),
                  );
                }

                return ListView.builder(
                  itemCount: provider.nearbyStands.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final stand = provider.nearbyStands[index];
                    return _AutoStandCard(
                      stand: stand,
                      onJoinRequest: () => provider.requestJoinAutoStand(stand.id),
                      isCurrentStand: provider.currentStand?.id == stand.id,
                    );
                  },
                );
              },
            ),
          ),
          if (context.select((AutoStandProvider p) => p.currentStand != null))
            const _QueueStatusBar(),
        ],
      ),
    );
  }
}

class _AutoStandCard extends StatelessWidget {
  final AutoStand stand;
  final VoidCallback onJoinRequest;
  final bool isCurrentStand;

  const _AutoStandCard({
    Key? key,
    required this.stand,
    required this.onJoinRequest,
    required this.isCurrentStand,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stand.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (stand.distance != null)
                  Text(
                    '${stand.distance!.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${stand.members.length} members',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (!isCurrentStand)
              ElevatedButton(
                onPressed: onJoinRequest,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
                child: const Text('Request to Join'),
              )
            else
              OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
                child: const Text('Current Stand'),
              ),
          ],
        ),
      ),
    );
  }
}

class _QueueStatusBar extends StatelessWidget {
  const _QueueStatusBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Consumer<AutoStandProvider>(
        builder: (context, provider, child) {
          final isInQueue = provider.isInQueue;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.currentStand?.name ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isInQueue ? 'In Queue' : 'Not in Queue',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isInQueue ? Colors.green : Colors.red,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isInQueue,
                onChanged: (value) => provider.toggleQueueStatus(value),
                activeColor: AppColors.primary,
              ),
            ],
          );
        },
      ),
    );
  }
} 