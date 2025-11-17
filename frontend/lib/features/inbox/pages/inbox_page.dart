import 'package:flutter/material.dart';

/// A simple placeholder inbox page that displays tabs for system,
/// customer and team messages.  In a full implementation this page
/// would load messages from Supabase and allow replying to team
/// messages.  This placeholder is provided to satisfy route
/// references during iOS builds.
class InboxPage extends StatefulWidget {
  const InboxPage({Key? key}) : super(key: key);

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nachrichten'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'System'),
            Tab(text: 'Kunden'),
            Tab(text: 'Team'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Center(child: Text('Systemnachrichten (noch nicht implementiert)')),
          Center(child: Text('Kundennachrichten (noch nicht implementiert)')),
          Center(child: Text('Teamnachrichten (noch nicht implementiert)')),
        ],
      ),
    );
  }
}