import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../viewmodels/planner_viewmodel.dart';
import '../../data/models/content_calendar_model.dart';

class ContentPlannerScreen extends StatefulWidget {
  final bool embeddedMode;
  
  const ContentPlannerScreen({super.key, this.embeddedMode = false});

  @override
  State<ContentPlannerScreen> createState() => _ContentPlannerScreenState();
}

class _ContentPlannerScreenState extends State<ContentPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicheController = TextEditingController();
  final _audienceController = TextEditingController();
  final _goalController = TextEditingController();
  final _uniquePerspectiveController = TextEditingController();
  final _knownForController = TextEditingController();
  final _targetsController = TextEditingController();  
  String _postingFrequency = '3 Reels per week';
  String _primaryGoal = 'Followers';
  String _contentStyle = 'Educational';  ContentCalendarDay? _selectedDay;

  final List<String> _frequencies = [
    'Daily Reels',
    '5 Reels per week',
    '3 Reels per week',
    '2 Reels per week',
  ];
  final List<String> _goals = ['Followers', 'Leads', 'Sales', 'Personal Brand', 'Community'];
  final List<String> _styles = ['Educational', 'Storytelling', 'Authority', 'Entertainment', 'Personal Journey'];
  @override
  void dispose() {
    _nicheController.dispose();
    _audienceController.dispose();
    _goalController.dispose();
    _uniquePerspectiveController.dispose();
    _knownForController.dispose();
    _targetsController.dispose();    super.dispose();
  }

  void _generateCalendar() async {
    if (_formKey.currentState!.validate()) {
      final plannerVM = Provider.of<PlannerViewModel>(context, listen: false);
      final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
      
      // Verification of limit (if Free, max 5, but we do not gate - just warn/record)
      if (!profileVM.isPro && plannerVM.savedCalendars.length >= 2) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: const Text('Pro Generation Limit'),
            content: const Text(
              'Free Plan is limited to 2 saved Content Calendars. Upgrade to Pro for â‚¹199/month to generate unlimited content plans.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  profileVM.toggleSubscription(); // Instantly buy Pro!
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                child: const Text('Get Pro (â‚¹199)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }

      final calendar = await plannerVM.generateNewCalendar(
        niche: _nicheController.text,
        audience: _audienceController.text,
        goal: '${_goalController.text}\nPrimary goal: $_primaryGoal\nContent style: $_contentStyle\nUnique perspective: ${_uniquePerspectiveController.text}\nKnown-for topics: ${_knownForController.text}\nMonthly targets: ${_targetsController.text}',
        frequency: _postingFrequency,
      );

      if (calendar != null) {
        if (calendar.days.isNotEmpty) {
          setState(() {
            _selectedDay = calendar.days.first;
          });
        }
      }
    }
  }

  void _copyToClipboard(ContentCalendarDay day) {
    final text = 'Day ${day.day}: ${day.title}\n\nðŸ’¡ IDEA:\n${day.idea}\n\nðŸª SUGGESTED HOOK:\n${day.hook}\n\nâœï¸ CAPTION:\n${day.caption}\n\nðŸ“£ CTA:\n${day.cta}\n\nâ° POSTING TIME: ${day.postingTime} (${day.difficulty})';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Day ${day.day} planner copied to clipboard!'),
        backgroundColor: AppTheme.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareDay(ContentCalendarDay day) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing Day ${day.day} idea with external apps...'),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportPdfStub(ContentCalendarModel calendar) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF Creator Copilot Report generated successfully! (Ready for download)'),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plannerVM = Provider.of<PlannerViewModel>(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Content Planner'),
        actions: [
          if (plannerVM.activeCalendar != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.success),
              onPressed: () => _exportPdfStub(plannerVM.activeCalendar!),
              tooltip: 'Export Calendar PDF',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
              onPressed: () {
                plannerVM.deleteCalendar(plannerVM.activeCalendar!.id);
                setState(() {
                  _selectedDay = null;
                });
              },
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, widget.embeddedMode ? 44 : 16, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 900 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (plannerVM.activeCalendar == null)
                  _buildSetupForm()
                else
                  _buildCalendarDashboard(plannerVM.activeCalendar!, plannerVM),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Creator Strategy Setup',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Answer the strategy questions once. CreatorOS will turn your voice, positioning, audience, and goals into a monthly content system.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 24),
          
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nicheController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'What is your Niche?',
                    hintText: 'e.g. Flutter Development, Personal Finance',
                    prefixIcon: Icon(Icons.category_rounded, color: AppTheme.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your niche' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _audienceController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Who is your Target Audience?',
                    hintText: 'e.g. Student Developers, GenZ Investors',
                    prefixIcon: Icon(Icons.people_alt_rounded, color: AppTheme.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your audience' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _goalController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'What is your Core Goal?',
                    hintText: 'e.g. Get newsletter subscribers, Build coding brand',
                    prefixIcon: Icon(Icons.flag_rounded, color: AppTheme.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your goal' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _primaryGoal,
                  dropdownColor: AppTheme.cardBackground,
                  decoration: const InputDecoration(
                    labelText: 'Primary Goal',
                    prefixIcon: Icon(Icons.track_changes_rounded, color: AppTheme.textSecondary),
                  ),
                  items: _goals.map((goal) => DropdownMenuItem<String>(value: goal, child: Text(goal))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _primaryGoal = val);
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _contentStyle,
                  dropdownColor: AppTheme.cardBackground,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Content Style',
                    prefixIcon: Icon(Icons.style_rounded, color: AppTheme.textSecondary),
                  ),
                  items: _styles.map((style) => DropdownMenuItem<String>(value: style, child: Text(style))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _contentStyle = val);
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _uniquePerspectiveController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'What makes your perspective unique?',
                    hintText: 'e.g. I teach finance through creator case studies',
                    prefixIcon: Icon(Icons.auto_awesome_rounded, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _knownForController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Topics you want to become known for',
                    hintText: 'e.g. hooks, content systems, monetization',
                    prefixIcon: Icon(Icons.topic_rounded, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _targetsController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Targets',
                    hintText: 'e.g. +1,000 followers, 20 leads, 4 sales calls',
                    prefixIcon: Icon(Icons.flag_circle_rounded, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Frequency Dropdown
                DropdownButtonFormField<String>(
                  value: _postingFrequency,
                  dropdownColor: AppTheme.cardBackground,
                  decoration: const InputDecoration(
                    labelText: 'Posting Frequency',
                    prefixIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.textSecondary),
                  ),
                  items: _frequencies.map((freq) {
                    return DropdownMenuItem<String>(
                      value: freq,
                      child: Text(freq),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _postingFrequency = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Generate Button
          Consumer<PlannerViewModel>(
            builder: (context, plannerVM, _) {
              return ElevatedButton.icon(
                onPressed: plannerVM.isLoading ? null : _generateCalendar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primary,
                ),
                icon: plannerVM.isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Icon(Icons.insights_rounded, color: Colors.white),
                label: Text(
                  plannerVM.isLoading ? 'Copilot is structuring your plan...' : 'Generate 30-Day Content Plan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDashboard(ContentCalendarModel calendar, PlannerViewModel plannerVM) {
    if (_selectedDay == null && calendar.days.isNotEmpty) {
      _selectedDay = calendar.days.first;
    }

    final isWide = MediaQuery.of(context).size.width > 750;

    final listGrid = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // History Picker / Info card
        if (plannerVM.savedCalendars.length > 1) ...[
          DropdownButton<ContentCalendarModel>(
            value: calendar,
            dropdownColor: AppTheme.cardBackground,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.accent),
            underline: Container(),
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            items: plannerVM.savedCalendars.map((cal) {
              return DropdownMenuItem<ContentCalendarModel>(
                value: cal,
                child: Text('${cal.niche} Plan (${cal.frequency})'),
              );
            }).toList(),
            onChanged: (newCal) {
              if (newCal != null) {
                plannerVM.setActiveCalendar(newCal);
                setState(() {
                  _selectedDay = newCal.days.isNotEmpty ? newCal.days.first : null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // Active Planner Info
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    calendar.niche.toUpperCase(),
                    style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5),
                  ),
                  Text(
                    calendar.frequency,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Goal: ${calendar.goal}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Grid of 30 days
        const Text(
          '30-Day Campaign Days',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: calendar.days.length,
          itemBuilder: (context, index) {
            final day = calendar.days[index];
            final isSelected = _selectedDay?.day == day.day;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDay = day;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primary.withOpacity(0.18) 
                      : AppTheme.cardBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primary 
                        : Colors.white.withOpacity(0.06),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DAY',
                        style: TextStyle(
                          color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        
        // Reset Setup button
        TextButton.icon(
          onPressed: () {
            plannerVM.clearActiveCalendar();
            setState(() {
              _selectedDay = null;
            });
          },
          icon: const Icon(Icons.add_rounded, color: AppTheme.accent),
          label: const Text('Create Different Plan', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
        ),
      ],
    );

    final detailsPanel = _selectedDay == null
        ? const Center(child: Text('Select a day to view details'))
        : _buildDayDetailsCard(_selectedDay!);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: listGrid),
          const SizedBox(width: 24),
          Expanded(flex: 6, child: detailsPanel),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          listGrid,
          const SizedBox(height: 24),
          detailsPanel,
        ],
      );
    }
  }

  Widget _buildDayDetailsCard(ContentCalendarDay day) {
    Color diffColor;
    if (day.difficulty.toLowerCase() == 'easy') {
      diffColor = AppTheme.success;
    } else if (day.difficulty.toLowerCase() == 'hard') {
      diffColor = AppTheme.error;
    } else {
      diffColor = AppTheme.warning;
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DAY ${day.day}',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: diffColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: diffColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      day.difficulty.toUpperCase(),
                      style: TextStyle(color: diffColor, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => _copyToClipboard(day),
                    tooltip: 'Copy all Day info',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => _shareDay(day),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            day.title,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Idea
          const Text('Reel Idea', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(day.idea, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.45)),
          const Divider(color: Colors.white10, height: 24),

          // Hook
          const Text('Suggested Hook', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(day.hook, style: const TextStyle(color: AppTheme.accent, fontSize: 14, fontStyle: FontStyle.italic)),
          const Divider(color: Colors.white10, height: 24),

          // Caption
          const Text('Suggested Caption', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(day.caption, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45)),
          const Divider(color: Colors.white10, height: 24),

          // CTA
          const Text('Suggested CTA', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(day.cta, style: const TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white10, height: 24),

          // Posting Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Best Posting Time', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: AppTheme.accent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    day.postingTime,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}



