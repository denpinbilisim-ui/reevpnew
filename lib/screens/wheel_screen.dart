import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import 'branches_screen.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSpinning = false;
  bool _canSpin = false;
  String? _nextSpinAt;
  Map<String, dynamic>? _lastPrize;
  List<dynamic> _prizes = [];
  List<dynamic> _history = [];
  bool _isLoadingHistory = false;

  AnimationController? _spinController;
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _loadWheelStatus();
  }

  @override
  void dispose() {
    _spinController?.dispose();
    super.dispose();
  }

  Future<void> _loadWheelStatus() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      final response = await apiService.getWheelStatus(
        userId: authService.user?['id']?.toString() ?? '',
        headers: authService.getAuthHeaders(),
      );

      if (mounted) {
        setState(() {
          _canSpin = response['can_spin'] == true;
          _nextSpinAt = response['next_spin_at'];
          _lastPrize = response['last_prize'];
          _prizes = response['prizes'] ?? [];
          _isLoading = false;
        });
        _loadWheelHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çark durumu yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _spin() async {
    if (_isSpinning || !_canSpin) return;

    setState(() => _isSpinning = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      final response = await apiService.spinWheel(
        userId: authService.user?['id']?.toString() ?? '',
        headers: authService.getAuthHeaders(),
      );

      if (response['success'] == true) {
        final prize = response['prize'] as Map<String, dynamic>;
        final prizeIndex = _prizes.indexWhere((p) => p['id'] == prize['id']);
        final segmentAngle = 2 * math.pi / _prizes.length;
        final targetAngle = prizeIndex * segmentAngle;

        _spinController = AnimationController(
          duration: const Duration(seconds: 4),
          vsync: this,
        );

        final startAngle = _currentAngle;
        final fullSpins = 5 * 2 * math.pi;
        final endAngle = startAngle + fullSpins + (2 * math.pi - targetAngle - segmentAngle / 2);

        final animation = CurvedAnimation(
          parent: _spinController!,
          curve: Curves.easeOutCubic,
        );

        _spinController!.addListener(() {
          setState(() {
            _currentAngle = startAngle + (endAngle - startAngle) * animation.value;
          });
        });

        _spinController!.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _isSpinning = false;
              _canSpin = false;
              _nextSpinAt = response['next_spin_at'];
            });
            _showPrizeDialog(
              prize,
              response['remaining_points'],
              response['redemption'],
            );
          }
        });

        _spinController!.forward();
      } else {
        if (mounted) {
          setState(() => _isSpinning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Çark çevrilemedi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSpinning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çark çevrilemedi: $e')),
        );
      }
    }
  }

  void _showPrizeDialog(
    Map<String, dynamic> prize,
    dynamic remainingPoints,
    dynamic redemption,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                prize['prize_type'] == 'points'
                    ? Icons.celebration
                    : Icons.card_giftcard,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Tebrikler!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                prize['name'] ?? '',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (prize['prize_type'] == 'points')
                Text(
                  '${prize['points_amount']} puan hesabınıza eklendi!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ),
                )
              else if (redemption != null)
                Column(
                  children: [
                    Text(
                      'Kazandığınız ürün: ${redemption['product_name']}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (redemption['qr_code_image'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(
                            (redemption['qr_code_image'] as String)
                                .split(',')
                                .last,
                          ),
                          width: 180,
                          height: 180,
                        ),
                      )
                    else if (redemption['qr_code_data'] != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: QrImageView(
                          data: redemption['qr_code_data'],
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Onay Kodu: ${redemption['confirmation_code']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu QR kodunu şubede göstererek ürününüzü alabilirsiniz.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Tamam',
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadWheelStatus();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNextSpin(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Şans Çarkı',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _loadWheelStatus,
                      icon: const Icon(Icons.refresh, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : _prizes.isEmpty
                        ? _buildEmptyState()
                        : _buildWheelContent(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.black38,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          currentIndex: 4,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacementNamed('/dashboard');
                break;
              case 1:
                Navigator.of(context).pushReplacementNamed('/campaigns');
                break;
              case 2:
                Navigator.of(context).pushReplacementNamed('/dashboard');
                break;
              case 3:
                Navigator.of(context).pushReplacementNamed('/redeem');
                break;
              case 4:
                break;
              case 5:
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BranchesScreen(),
                  ),
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: 'Kampanyalar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_outlined),
              activeIcon: Icon(Icons.qr_code),
              label: 'QR Olu\u015ftur',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.redeem_outlined),
              activeIcon: Icon(Icons.redeem),
              label: 'Puan Kullan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.casino),
              label: '\u015eans \u00c7ark\u0131',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: '\u015eubeler',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.casino_outlined,
            size: 64,
            color: Colors.black.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Şu anda çark için ödül tanımlı değil',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status card
          if (!_canSpin && _nextSpinAt != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu hafta çarkı çevirdiniz',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tekrar çevirme: ${_formatNextSpin(_nextSpinAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Last prize info
          if (_lastPrize != null && !_canSpin)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Row(
                children: [
                  Icon(
                    _lastPrize!['prize_type'] == 'points'
                        ? Icons.celebration
                        : Icons.card_giftcard,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Geçen haftaki ödülünüz: ${_lastPrize!['name']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          // Wheel
          _buildWheel(),
          const SizedBox(height: 24),
          // Spin button
          CustomButton(
            text: _canSpin ? 'Çarkı Çevir' : 'Tekrar Pazartesi',
            onPressed: _canSpin && !_isSpinning ? _spin : null,
            isLoading: _isSpinning,
            icon: Icons.casino,
          ),
          const SizedBox(height: 24),
          // Prize list
          _buildPrizeList(),
          const SizedBox(height: 24),
          // History
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildWheel() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wheel
          Transform.rotate(
            angle: _currentAngle,
            child: CustomPaint(
              size: const Size(280, 280),
              painter: WheelPainter(prizes: _prizes),
            ),
          ),
          // Center hub
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 24,
            ),
          ),
          // Pointer arrow at top
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(30, 30),
              painter: PointerPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ödüller',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...(_prizes.map((prize) => _buildPrizeItem(prize)).toList()),
        ],
      ),
    );
  }

  Widget _buildPrizeItem(Map<String, dynamic> prize) {
    final color = _parseColor(prize['color']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prize['name'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  ),
            ),
          ),
          Text(
            prize['prize_type'] == 'points'
                ? '${prize['points_amount']} puan'
                : 'Ürün',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppTheme.primaryColor;
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  Future<void> _loadWheelHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      final response = await apiService.getWheelHistory(
        userId: authService.user?['id']?.toString() ?? '',
        headers: authService.getAuthHeaders(),
      );

      if (mounted) {
        setState(() {
          _history = response['history'] ?? [];
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Geçmiş Kazanımlarım',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            )
          else if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Henüz çark kazanımınız yok',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ),
            )
          else
            ..._history.map((item) => _buildHistoryItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final prizeType = item['prize_type'] ?? 'points';
    final isProduct = prizeType == 'product';
    final isConfirmed = item['is_confirmed'] == true;
    final spunAt = item['spun_at'] != null ? _formatNextSpin(item['spun_at']) : '';

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Icon(
        isProduct ? Icons.card_giftcard : Icons.celebration,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        item['prize_name'] ?? '',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
      ),
      subtitle: Text(
        isProduct
            ? 'Ürün ödülü - $spunAt'
            : '${item['points_awarded'] ?? 0} puan - $spunAt',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black54,
            ),
      ),
      trailing: isProduct
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConfirmed ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isConfirmed ? 'Teslim Edildi' : 'Bekliyor',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      children: [
        if (isProduct) ...[
          if (item['qr_code_image'] != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(
                    (item['qr_code_image'] as String).split(',').last,
                  ),
                  width: 160,
                  height: 160,
                ),
              ),
            )
          else if (item['qr_code_data'] != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: QrImageView(
                  data: item['qr_code_data'],
                  version: QrVersions.auto,
                  size: 160,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (item['product_name'] != null)
            Text(
              'Ürün: ${item['product_name']}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          const SizedBox(height: 4),
          if (item['confirmation_code'] != null)
            Text(
              'Onay Kodu: ${item['confirmation_code']}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          const SizedBox(height: 8),
          Text(
            isConfirmed
                ? 'Bu ödül teslim edildi.'
                : 'Bu QR kodunu şubede göstererek ürününüzü alabilirsiniz.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${item['points_awarded'] ?? 0} puan hesabınıza eklendi.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<dynamic> prizes;

  WheelPainter({required this.prizes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / prizes.length;

    for (int i = 0; i < prizes.length; i++) {
      final prize = prizes[i];
      final startAngle = i * segmentAngle - math.pi / 2;
      final sweepAngle = segmentAngle;

      // Segment color
      final hexColor = (prize['color'] as String?)?.replaceAll('#', '') ?? '8B5E3C';
      final color = Color(int.parse('FF$hexColor', radix: 16));

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Segment border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Prize text
      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: _shortName(prize['name'] ?? ''),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  String _shortName(String name) {
    if (name.length <= 12) return name;
    return '${name.substring(0, 10)}..';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
