import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';
import 'package:anantata/data/assessment_questions.dart';

/// Екран кар'єрного оцінювання v2.1
/// 15 питань з прогрес-баром та валідацією
/// Версія: 2.1 - Прибрано іконку категорії
/// Дата: 13.12.2025

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
  int _currentQuestionIndex = 0;
  final Map<int, String> _answers = {};
  final TextEditingController _customAnswerController = TextEditingController();
  bool _isCustomSelected = false;

  AssessmentQuestion get _currentQuestion =>
      assessmentQuestions[_currentQuestionIndex];

  int get _totalQuestions => assessmentQuestions.length;

  double get _progress => (_currentQuestionIndex + 1) / _totalQuestions;

  bool get _canProceed {
    final answer = _answers[_currentQuestion.id];
    if (answer == null || answer.isEmpty) return false;
    if (_isCustomSelected && _customAnswerController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _customAnswerController.dispose();
    super.dispose();
  }

  void _selectOption(String option) {
    setState(() {
      if (option.startsWith('💡')) {
        _isCustomSelected = true;
        _answers[_currentQuestion.id] = _customAnswerController.text.trim();
      } else {
        _isCustomSelected = false;
        _answers[_currentQuestion.id] = option;
        _customAnswerController.clear();
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

    if (_currentQuestionIndex < _totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _loadSavedAnswer();
      });
    } else {
      _submitAssessment();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _loadSavedAnswer();
      });
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
          // Прогрес
          _buildProgressSection(),

          // Питання та відповіді
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionCard(),
                  const SizedBox(height: 24),
                  ..._currentQuestion.options.map(_buildOptionCard),
                  if (_isCustomSelected) ...[
                    const SizedBox(height: 16),
                    _buildCustomInputField(),
                  ],
                ],
              ),
            ),
          ),

          // Кнопка "Далі"
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Питання ${_currentQuestionIndex + 1} з $_totalQuestions',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildOptionCard(String option) {
    final isSelected = _isCustomSelected
        ? option.startsWith('💡')
        : _answers[_currentQuestion.id] == option;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _selectOption(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                width: 24,
                height: 24,
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
                  size: 16,
                  color: AppTheme.primaryColor,
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildCustomInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: _customAnswerController,
        onChanged: _updateCustomAnswer,
        decoration: const InputDecoration(
          hintText: 'Введіть вашу відповідь...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(fontSize: 16),
        maxLines: 3,
        minLines: 1,
      ),
    );
  }

  Widget _buildBottomButton() {
    final isLastQuestion = _currentQuestionIndex == _totalQuestions - 1;

    return Container(
      padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Кнопка "Назад"
            TextButton.icon(
              onPressed: _previousQuestion,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Назад'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            const Spacer(),
            // Кнопка "Далі" або "Завершити"
            ElevatedButton.icon(
              onPressed: _canProceed ? _nextQuestion : null,
              icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
              label: Text(isLastQuestion ? 'Завершити' : 'Далі'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}