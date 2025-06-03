import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LazyExpansionTile extends StatefulWidget {
  final String title;
  final List<Widget> children;

  const LazyExpansionTile({
    required this.title,
    required this.children,
    Key? key,
  }) : super(key: key);

  @override
  _LazyExpansionTileState createState() => _LazyExpansionTileState();
}

class _LazyExpansionTileState extends State<LazyExpansionTile> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _arrowAnimation = Tween<double>(begin: 0, end: 0.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _handleTap() async {
    if (!_isExpanded && !_isLoading) {
      setState(() => _isLoading = true);
      await Future.delayed(Duration(milliseconds: 300));
      setState(() {
        _isExpanded = true;
        _isLoading = false;
        _controller.forward();
      });
    } else {
      setState(() {
        _isExpanded = !_isExpanded;
        if (_isExpanded) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            onTap: _handleTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  RotationTransition(
                    turns: _arrowAnimation,
                    child: Icon(Icons.expand_more, color: Colors.red.shade900),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(color: Colors.red.shade700),
            ),

          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Container(
              constraints: BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: widget.children.length,
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
                itemBuilder: (context, index) => widget.children[index],
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
