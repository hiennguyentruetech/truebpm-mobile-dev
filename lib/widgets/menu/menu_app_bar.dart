import 'package:flutter/material.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/utils/app_strings.dart';

class MenuAppBar extends StatelessWidget {
  final UserModel? currentUser;

  const MenuAppBar({
    super.key,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings();
    
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 250,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      elevation: 0,
      stretch: true,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double expandRatio = constraints.maxHeight > 80
              ? (300 - constraints.maxHeight) / (300 - 80)
              : 1.0;
          
          final bool isExpanded = expandRatio <= 0.35;
          final bool isCollapsed = expandRatio >= 0.55;
          final double logoSize = isCollapsed ? 35.0 : 65.0;
          final double titleSize = isCollapsed ? 16.0 : 24.0;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade300,
                  Colors.blue.shade600,
                  Colors.blue.shade900,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Animated background particles effect
                _buildBackgroundEffect(isExpanded),
                
                // App Logo with smooth animation
                _buildAnimatedLogo(context, isCollapsed, logoSize),

                // App Title with dynamic positioning
                _buildAnimatedTitle(
                  context, 
                  appStrings, 
                  isCollapsed, 
                  logoSize, 
                  titleSize
                ),

                // Welcome Section with elegant fade
                if (currentUser != null)
                  _buildWelcomeSection(context, isExpanded),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundEffect(bool isExpanded) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: isExpanded ? 0.1 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(BuildContext context, bool isCollapsed, double logoSize) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      left: isCollapsed ? 16 : (MediaQuery.of(context).size.width - logoSize) / 2,
      top: isCollapsed
          ? MediaQuery.of(context).padding.top + 10
          : MediaQuery.of(context).padding.top + 7,
      child: Hero(
        tag: 'app_logo_hero',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: isCollapsed ? 8 : 16,
                offset: Offset(0, isCollapsed ? 2 : 4),
                spreadRadius: isCollapsed ? 1 : 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/logos/app_logo.jpg',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business_center_rounded,
                    size: logoSize * 0.5,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle(
    BuildContext context,
    AppStrings appStrings,
    bool isCollapsed,
    double logoSize,
    double titleSize,
  ) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      left: isCollapsed ? logoSize + 32 : 0,
      right: isCollapsed ? 16 : 0,
      top: isCollapsed ? 
        MediaQuery.of(context).padding.top + 20 : 
        MediaQuery.of(context).padding.top + 120 - 40,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        style: TextStyle(
          fontSize: titleSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: isCollapsed ? 0.5 : 1.2,
          shadows: [
            Shadow(
              offset: const Offset(0, 2),
              blurRadius: 8,
              color: Colors.black.withOpacity(0.4),
            ),
          ],
        ),
        child: Container(
          alignment: isCollapsed ? Alignment.centerLeft : Alignment.center,
          child: Text(
            appStrings.loginTitle,
            textAlign: isCollapsed ? TextAlign.left : TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isExpanded) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutQuart,
      left: 16,
      right: 16,
      top: isExpanded ? 
        MediaQuery.of(context).padding.top + 170 - 50: 
        MediaQuery.of(context).padding.top + 400 - 30,
      child: AnimatedOpacity(
        opacity: isExpanded ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'WELCOME!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currentUser!.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (currentUser!.position != null && currentUser!.position!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentUser!.position!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
