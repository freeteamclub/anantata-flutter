import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/data/assessment_questions.dart';

/// Екран кар'єрного оцінювання v2.4
/// 15 питань з прогрес-баром та валідацією
/// Версія: 2.4 - Додано вступний екран з поясненням
/// Дата: 21.12.2025
///
/// Виправлено:
/// - Баг #10 - кнопка "Завершити" на малих екранах
/// - Баг #2 - автопідйом поля "Ваш варіант" при клавіатурі
/// - Баг #7 - прогрес 100% тільки після відповіді на останнє питання
/// - Допрацювання #7 - вступний екран з поясненням процесу

class AssessmentScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final Function(Map<int, String> answers)? onSubmit;
  final VoidCallback? onBack;

  const AssessmentScreen({
    super.key,
    this.onComplete,
    this.onSubmit,
    this.onBack,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  // Допрацювання #7: Стан для показу вступного екрану
  bool _showIntro = true;

  int _currentQuestionIndex = 0;
  final Map<int, String> _answers = {};
  final TextEditingController _customAnswerController = TextEditingController();
  bool _isCustomSelected = false;

  // Для автопідйому поля вводу (Баг #2)
  final ScrollController _scrollController = ScrollController();
  final FocusNode _customInputFocusNode = FocusNode();
  final GlobalKey _customInputKey = GlobalKey();

  AssessmentQuestion get _currentQuestion =>
      assessmentQuestions[_currentQuestionIndex];

  int get _totalQuestions => assessmentQuestions.length;

  // Баг #7: Прогрес рахується по кількості відповідей, а не по індексу питання
  double get _progress {
    int answeredCount = 0;
    for (int i = 0; i < _totalQuestions; i++) {
      final questionId = assessmentQuestions[i].id;
      final answer = _answers[questionId];
      if (answer != null && answer.isNotEmpty) {
        answeredCount++;
      }
    }
    return answeredCount / _totalQuestions;
  }

  bool get _canProceed {
    final answer = _answers[_currentQuestion.id];
    if (answer == null || answer.isEmpty) return false;
    if (_isCustomSelected && _customAnswerController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _customInputFocusNode.addListener(_onCustomInputFocusChange);
  }

  @override
  void dispose() {
    _customAnswerController.dispose();
    _scrollController.dispose();
    _customInputFocusNode.removeListener(_onCustomInputFocusChange);
    _customInputFocusNode.dispose();
    super.dispose();
  }

  // Допрацювання #7: Почати оцінювання (закрити intro)
  void _startAssessment() {
    setState(() {
      _showIntro = false;
    });
  }

  // Баг #2: Автоскрол до поля вводу
  void _onCustomInputFocusChange() {
    if (_customInputFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToCustomInput();
      });
    }
  }

  void _scrollToCustomInput() {
    if (_customInputKey.currentContext != null) {
      Scrollable.ensureVisible(
        _customInputKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }

  void _selectOption(String option) {
    setState(() {
      if (option.startsWith('💡')) {
        _isCustomSelected = true;
        _answers[_currentQuestion.id] = _customAnswerController.text.trim();
        Future.delayed(const Duration(milliseconds: 100), () {
          _customInputFocusNode.requestFocus();
        });
      } else {
        _isCustomSelected = false;
        _answers[_currentQuestion.id] = option;
        _customAnswerController.clear();
        _customInputFocusNode.unfocus();
      }
    });
  }

  void _updateCustomAnswer(String value) {
    setState(() {
      _answers[_currentQuestion.id] = value.trim();
    });
  }

  void _nextQuestion() {
    if (!_canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Будь ласка, оберіть або введіть відповідь'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _customInputFocusNode.unfocus();

    if (_currentQuestionIndex < _totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _loadSavedAnswer();
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _submitAssessment();
    }
  }

  void _previousQuestion() {
    _customInputFocusNode.unfocus();

    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _loadSavedAnswer();
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _showExitDialog();
    }
  }

  void _loadSavedAnswer() {
    final savedAnswer = _answers[_currentQuestion.id];
    if (savedAnswer != null) {
      final isCustom = !_currentQuestion.options.contains(savedAnswer);
      _isCustomSelected = isCustom;
      if (isCustom) {
        _customAnswerController.text = savedAnswer;
      } else {
        _customAnswerController.clear();
      }
    } else {
      _isCustomSelected = false;
      _customAnswerController.clear();
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вийти з оцінювання?'),
        content: const Text('Ваш прогрес буде втрачено.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Залишитись'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBack?.call();
            },
            child: const Text('Вийти'),
          ),
        ],
      ),
    );
  }

  void _submitAssessment() {
    widget.onSubmit?.call(_answers);
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Допрацювання #7: Показуємо вступний екран
    if (_showIntro) {
      return _buildIntroScreen();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _previousQuestion,
        ),
        title: const Text(
          'Кар\'єрна оцінка',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressSection(isSmallScreen),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionCard(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  ..._currentQuestion.options.map(
                        (option) => _buildOptionCard(option, isSmallScreen),
                  ),
                  if (_isCustomSelected) ...[
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    _buildCustomInputField(isSmallScreen),
                  ],
                  SizedBox(height: _isCustomSelected ? 120 : 20),
                ],
              ),
            ),
          ),
          _buildBottomButton(isSmallScreen),
        ],
      ),
    );
  }

  // Допрацювання #7: Вступний екран з поясненням
  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[600]),
          onPressed: () {
            widget.onBack?.call();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Іконка
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 56,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // Заголовок
              const Text(
                'Кар\'єрна оцінка',
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Підзаголовок
              Text(
                'Дізнайтеся свій потенціал та отримайте\nперсональний план розвитку',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Пункти пояснення
              _buildInfoItem(
                icon: Icons.timer_outlined,
                title: '15 питань • ~5 хвилин',
                subtitle: 'Швидке та просте проходження',
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                icon: Icons.psychology_outlined,
                title: 'AI аналіз відповідей',
                subtitle: 'Штучний інтелект оцінить ваш профіль',
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                icon: Icons.checklist_rounded,
                title: '100 кроків до мети',
                subtitle: 'Отримаєте детальний план розвитку',
              ),

              const Spacer(flex: 2),

              // Кнопка "Почати"
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _startAssessment,
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text(
                    'Почати оцінювання',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Додаткова інформація
              Text(
                'Ваші відповіді зберігаються локально',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  // Допрацювання #7: Елемент списку пояснень
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Питання ${_currentQuestionIndex + 1} з $_totalQuestions',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: isSmallScreen ? 4 : 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _currentQuestion.text,
        style: TextStyle(
          fontSize: isSmallScreen ? 16 : 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildOptionCard(String option, bool isSmallScreen) {
    final isSelected = _isCustomSelected
        ? option.startsWith('💡')
        : _answers[_currentQuestion.id] == option;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      child: GestureDetector(
        onTap: () => _selectOption(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: isSmallScreen ? 20 : 24,
                height: isSmallScreen ? 20 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.grey,
                    width: 2,
                  ),
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                  Icons.check,
                  size: isSmallScreen ? 12 : 16,
                  color: AppTheme.primaryColor,
                )
                    : null,
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomInputField(bool isSmallScreen) {
    return Container(
      key: _customInputKey,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _customAnswerController,
        focusNode: _customInputFocusNode,
        onChanged: _updateCustomAnswer,
        decoration: InputDecoration(
          hintText: 'Введіть вашу відповідь...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        maxLines: 3,
        minLines: 1,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          _customInputFocusNode.unfocus();
        },
      ),
    );
  }

  Widget _buildBottomButton(bool isSmallScreen) {
    final isLastQuestion = _currentQuestionIndex == _totalQuestions - 1;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        minimum: EdgeInsets.only(bottom: isSmallScreen ? 4 : 0),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _previousQuestion,
              icon: Icon(Icons.arrow_back, size: isSmallScreen ? 18 : 24),
              label: Text(
                'Назад',
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 8 : 12,
                ),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: isSmallScreen ? 44 : 48,
              child: ElevatedButton.icon(
                onPressed: _canProceed ? _nextQuestion : null,
                icon: Icon(
                  isLastQuestion ? Icons.check : Icons.arrow_forward,
                  size: isSmallScreen ? 18 : 24,
                ),
                label: Text(
                  isLastQuestion ? 'Завершити' : 'Далі',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  minimumSize: Size(isSmallScreen ? 120 : 140, 44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}