import 'package:flutter/material.dart';
import 'package:flutter_demo/constants/app_constants.dart';
import 'package:flutter_demo/constants/color_constants.dart';
import 'package:flutter_demo/constants/size_constants.dart';
import 'package:flutter_demo/widgets/page_header_widget.dart';
import 'package:flutter_svg/svg.dart';
import 'package:responsive_builder/responsive_builder.dart';

class Navbar extends StatefulWidget implements PreferredSizeWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight * 1.34); //56*1.34=75.4
}

class _NavbarState extends State<Navbar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile:
          (_) =>
              SizedBox(height: kToolbarHeight * 2, child: _buildMobileLayout()),
      tablet: (_) => SizedBox(),
      desktop: (_) => SizedBox(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Container(
          height: kToolbarHeight * 1.34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(whiteColor),
            boxShadow: [
              BoxShadow(
                color: const Color(blackColor).withAlpha(10),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: SvgPicture.asset(
                  AppImages.appLogo,
                  width: SizeConstants.appLogoWidth,
                  height: SizeConstants.appLogoHeight,
                  fit: BoxFit.contain,
                ),
              ),
              PageHeaderWidget(title: 'Calendar'),
              InkWell(
                onTap: () {
                  print('icon room list tap');
                },
                child: Image.asset(
                  AppIcons.iconRoomList,
                  width: SizeConstants.iconWidth,
                  height: SizeConstants.iconHeight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
