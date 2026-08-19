import 'package:care_mall_rider/app/commenwidget/apptext.dart';
import 'package:care_mall_rider/app/theme_data/app_colors.dart';
import 'package:care_mall_rider/app/utils/screen_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextFeild extends StatefulWidget {
  const AppTextFeild({
    super.key,
    required this.controller,
    this.titlelabale,
    this.hint,
    this.isobsecure,
    this.texttype,
    this.height,
    this.width,
    this.vcontentpadding,
    this.prefixicon,
    this.suffixIcon,
    this.readOnly,
    this.onTap,
    this.onChanged,
    this.contentalign,
    this.border,
    this.filled,
    this.filledcolor,
    this.hintStyle,
    this.textstyle,
    this.labelshow,
    this.digitsonly,
    this.multiline = 1,
    this.validator,
    this.focusNode,
    this.isrequired = false,
    this.sufixdrop = false,
    this.borderRadius = 7.0, // New parameter for border radius
    this.hintTextSize = 14.0, // New parameter for hint text size
    this.hintTextColor, // New parameter for hint text color
    this.textCapitalization =
        TextCapitalization.none, // New parameter for text capitalization
    this.inputFormatters, // New parameter for input formatters
    this.prefixWidget, // New parameter for prefix widget
  });

  final TextEditingController controller;
  final String? titlelabale, hint;
  final TextInputType? texttype;
  final FormFieldValidator<String>? validator;
  final TextStyle? textstyle, hintStyle;
  final bool? isobsecure,
      readOnly,
      labelshow,
      digitsonly,
      isrequired,
      sufixdrop,
      filled;
  final Widget? suffixIcon, prefixicon, prefixWidget;
  final double? height,
      width,
      vcontentpadding,
      borderRadius,
      hintTextSize; // Added borderRadius and hintTextSize
  final int? multiline;
  final Color? filledcolor, hintTextColor; // Added hintTextColor
  final FocusNode? focusNode;
  final TextAlign? contentalign;
  final OutlineInputBorder? border;
  final Function()? onTap;
  final Function(String value)? onChanged;
  final TextCapitalization textCapitalization; // Added textCapitalization
  final List<TextInputFormatter>? inputFormatters; // Added inputFormatters

  @override
  State<AppTextFeild> createState() => _AppTextFeildState();
}

class _AppTextFeildState extends State<AppTextFeild> {
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isobsecure ?? false;
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return SizedBox(
      width: widget.width ?? ScreenUtil.screenWidth,
      child: Center(
        child: TextFormField(
          focusNode: widget.focusNode,
          validator: widget.validator,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          obscureText: _obscureText,
          controller: widget.controller,
          textCapitalization: widget.textCapitalization,
          keyboardType: widget.texttype ?? TextInputType.text,
          readOnly: widget.readOnly ?? false,
          maxLines: widget.multiline,
          style:
              widget.textstyle ??
              const TextStyle(
                color: AppColors.blackcolor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
          inputFormatters:
              widget.inputFormatters ??
              (widget.digitsonly == true
                  ? <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ]
                  : []),
          textAlign: widget.contentalign ?? TextAlign.start,
          decoration: InputDecoration(
            label: widget.labelshow == true
                ? AppText(
                    text: widget.titlelabale ?? '',
                    color: AppColors.blackcolor.withValues(alpha: 0.9),
                    fontSize: 12,
                    letterspace: 0.8,
                    fontWeight: FontWeight.w400,
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: widget.multiline != null
                  ? 8
                  : widget.vcontentpadding ?? 0,
            ),
            filled: widget.filled,
            fillColor:
                widget.filledcolor ??
                AppColors.blackcolor.withValues(alpha: 0.25),
            hintText: widget.hint,
            prefixIcon: widget.prefixicon,
            prefix: widget.prefixWidget,
            suffixIcon: widget.isobsecure == true
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.blackcolor.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.sufixdrop == true
                ? Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.blackcolor.withValues(alpha: 0.5),
                  )
                : widget.suffixIcon,
            hintStyle:
                widget.hintStyle ??
                TextStyle(
                  color:
                      widget.hintTextColor ??
                      AppColors.blackcolor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w300,
                  fontSize: widget.hintTextSize, // Use the new hintTextSize
                  fontFamily: '',
                ),
            border:
                widget.border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius ?? 7),
                  borderSide: BorderSide(
                    color: AppColors.bordercolor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
            focusedBorder:
                widget.border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius ?? 7),
                  borderSide: BorderSide(
                    color: AppColors.primarycolor,
                    width: 1,
                  ),
                ),
            disabledBorder:
                widget.border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius ?? 7),
                  borderSide: const BorderSide(
                    color: AppColors.primarycolor,
                    width: 1,
                  ),
                ),
            enabledBorder:
                widget.border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius ?? 7),
                  borderSide: BorderSide(
                    color: AppColors.bordercolor,
                    width: 1,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
