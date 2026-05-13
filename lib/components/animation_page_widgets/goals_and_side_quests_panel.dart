import 'dart:math' as math;
import 'package:focusdesk/providers/app_provider.dart';
import 'package:focusdesk/providers/quests_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';



class GoalsAndSideQuestsPanel extends StatefulWidget {
  const GoalsAndSideQuestsPanel({super.key});

  @override
  State<GoalsAndSideQuestsPanel> createState() => _GoalsAndSideQuestsPanelState();
}

class _GoalsAndSideQuestsPanelState extends State<GoalsAndSideQuestsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showSideQuests = false;

  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  void _toggleView() {
    FocusScope.of(context).unfocus();
    if (_showSideQuests) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showSideQuests = !_showSideQuests);
  }

  Widget _buildMainGoals(AppProvider provider) {
    final goals = provider.savedGoals;
    final goalStates = provider.goalStates;

    return Column(
      children: [
        Expanded(
          child: goals.isEmpty
              ? Center(
            child: Text(
              "No Main Goals Set",
              style: GoogleFonts.orbitron(color: Colors.white54),
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final isDone = goalStates[goal] ?? false;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Checkbox(
                    value: isDone,
                    activeColor: Colors.cyanAccent,
                    checkColor: Colors.black,
                    side: const BorderSide(color: Colors.white54),
                    onChanged: (val) =>
                        provider.toggleGoalStatus(goal, val ?? false),
                  ),
                  title: Text(
                    goal,
                    style: GoogleFonts.orbitron(
                      color: isDone ? Colors.white38 : Colors.white,
                      fontSize: 16,
                      decoration:
                      isDone ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.cyanAccent,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSideQuests(BuildContext context) {
    final questsProvider = context.watch<QuestsProvider>();
    final sideQuests = questsProvider.sideQuests;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: TextField(
                  controller: _taskController,
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Add side quest...",
                    hintStyle: GoogleFonts.orbitron(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      questsProvider.addSideQuest(val);
                      _taskController.clear();
                    }
                  },
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (_taskController.text.trim().isNotEmpty) {
                  questsProvider.addSideQuest(_taskController.text);
                  _taskController.clear();
                }
              },
              icon: const Icon(Icons.add_circle, color: Colors.orangeAccent),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: sideQuests.isEmpty
              ? Center(
            child: Text(
              "No Side Quests Active",
              style: GoogleFonts.orbitron(
                  color: Colors.white24, fontSize: 12),
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: sideQuests.length,
            itemBuilder: (context, index) {
              final item = sideQuests[index];
              final isDone = item['isDone'] as bool;
              return Dismissible(
                key: UniqueKey(),
                onDismissed: (_) =>
                    questsProvider.deleteSideQuest(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: isDone,
                      activeColor: Colors.orangeAccent,
                      checkColor: Colors.black,
                      side: const BorderSide(color: Colors.white38),
                      onChanged: (val) => questsProvider
                          .toggleSideQuestStatus(index, val ?? false),
                    ),
                    title: Text(
                      item['title'] as String,
                      style: GoogleFonts.orbitron(
                        color:
                        isDone ? Colors.white38 : Colors.white70,
                        fontSize: 14,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.orangeAccent,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _showSideQuests ? "SIDE QUESTS" : "TODAY'S GOALS",
                    key: ValueKey<bool>(_showSideQuests),
                    style: GoogleFonts.orbitron(
                      color: _showSideQuests
                          ? Colors.orangeAccent
                          : Colors.cyanAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleView,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showSideQuests ? Icons.flag : Icons.task_alt,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showSideQuests ? "GOALS" : "QUESTS",
                          style: GoogleFonts.orbitron(
                              color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),

            // 3D Flip Content
            Expanded(
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final double angle = _flipAnimation.value * math.pi;
                  final bool isBack = angle >= (math.pi / 2);
                  final Matrix4 transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle);

                  return Transform(
                    transform: transform,
                    alignment: Alignment.center,
                    child: isBack
                        ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _buildSideQuests(context),
                    )
                        : _buildMainGoals(provider),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}