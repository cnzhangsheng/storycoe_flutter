import 'package:flutter/material.dart';

/// ========================================
/// 绘本书架尺寸配置
/// ========================================
class BookshelfConfig {
  /// 每行列数（固定3列）
  final int columnsPerPage;

  /// 页面左右总 padding（安全边距，适配刘海屏）
  final double horizontalPadding;

  /// Grid 横向间距
  final double crossAxisSpacing;

  /// Grid 纵向间距
  final double mainAxisSpacing;

  /// 封面宽高比例 (宽:高) - 童书常用 3:4
  final double coverAspectRatio;

  /// 最小封面宽度
  final double minCoverWidth;

  /// 最大封面宽度
  final double maxCoverWidth;

  /// 标题区域高度
  final double titleAreaHeight;

  const BookshelfConfig({
    this.columnsPerPage = 3,
    this.horizontalPadding = 32.0, // 安全边距：左16 + 右16
    this.crossAxisSpacing = 12.0,
    this.mainAxisSpacing = 16.0,
    this.coverAspectRatio = 3.0 / 4.0,
    this.minCoverWidth = 80.0,
    this.maxCoverWidth = 200.0,
    this.titleAreaHeight = 32.0,
  });

  /// 手机竖屏默认配置
  static const BookshelfConfig phonePortrait = BookshelfConfig();

  /// 手机横屏配置
  static const BookshelfConfig phoneLandscape = BookshelfConfig(
    horizontalPadding: 48.0,
    mainAxisSpacing: 20.0,
  );

  /// 平板竖屏配置
  static const BookshelfConfig tabletPortrait = BookshelfConfig(
    horizontalPadding: 48.0,
    crossAxisSpacing: 16.0,
    mainAxisSpacing: 24.0,
    titleAreaHeight: 48.0,
    minCoverWidth: 120.0,
    maxCoverWidth: 280.0,
  );

  /// 平板横屏配置
  static const BookshelfConfig tabletLandscape = BookshelfConfig(
    horizontalPadding: 64.0,
    crossAxisSpacing: 20.0,
    mainAxisSpacing: 28.0,
    titleAreaHeight: 52.0,
    minCoverWidth: 140.0,
    maxCoverWidth: 300.0,
  );

  /// 复制并修改配置
  BookshelfConfig copyWith({
    int? columnsPerPage,
    double? horizontalPadding,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    double? coverAspectRatio,
    double? minCoverWidth,
    double? maxCoverWidth,
    double? titleAreaHeight,
  }) {
    return BookshelfConfig(
      columnsPerPage: columnsPerPage ?? this.columnsPerPage,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      crossAxisSpacing: crossAxisSpacing ?? this.crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing ?? this.mainAxisSpacing,
      coverAspectRatio: coverAspectRatio ?? this.coverAspectRatio,
      minCoverWidth: minCoverWidth ?? this.minCoverWidth,
      maxCoverWidth: maxCoverWidth ?? this.maxCoverWidth,
      titleAreaHeight: titleAreaHeight ?? this.titleAreaHeight,
    );
  }
}

/// ========================================
/// 绘本封面尺寸计算结果
/// ========================================
class BookCoverSize {
  /// 封面宽度
  final double width;

  /// 封面高度（按 3:4 比例）
  final double height;

  /// GridView 的 childAspectRatio（包含标题区域）
  final double gridAspectRatio;

  /// 是否被约束（超出最小/最大限制）
  final bool isConstrained;

  const BookCoverSize({
    required this.width,
    required this.height,
    required this.gridAspectRatio,
    this.isConstrained = false,
  });

  @override
  String toString() =>
      'BookCoverSize(width: ${width.toStringAsFixed(1)}, '
      'height: ${height.toStringAsFixed(1)}, '
      'ratio: ${gridAspectRatio.toStringAsFixed(3)})';
}

/// ========================================
/// 绘本书架尺寸计算工具类
///
/// 核心算法：
/// 1. 可用宽度 = 屏幕宽度 - 安全边距
/// 2. 单列宽度 = (可用宽度 - 横向总间距) / 列数
/// 3. 封面高度 = 封面宽度 / (宽高比 3:4) = 封面宽度 * 4/3
/// 4. GridView比例 = 封面宽度 / (封面高度 + 标题区域高度)
/// ========================================
class BookshelfSizer {
  BookshelfSizer._();

  /// 根据设备自动选择配置
  static BookshelfConfig getConfigForDevice(double screenWidth, Orientation orientation) {
    // 平板判断：最短边 > 600dp
    final isTablet = screenWidth > 600;

    if (isTablet) {
      return orientation == Orientation.landscape
          ? BookshelfConfig.tabletLandscape
          : BookshelfConfig.tabletPortrait;
    } else {
      return orientation == Orientation.landscape
          ? BookshelfConfig.phoneLandscape
          : BookshelfConfig.phonePortrait;
    }
  }

  /// 计算绘本封面尺寸
  static BookCoverSize calculate(double screenWidth, BookshelfConfig config) {
    // 【步骤1】计算可用宽度
    final availableWidth = screenWidth - config.horizontalPadding;

    // 【步骤2】计算单列宽度
    // 公式：(可用宽度 - (列数-1) * 横向间距) / 列数
    final totalSpacing = config.crossAxisSpacing * (config.columnsPerPage - 1);
    final rawWidth = (availableWidth - totalSpacing) / config.columnsPerPage;

    // 【步骤3】应用宽度约束
    double coverWidth;
    bool isConstrained = false;

    if (rawWidth < config.minCoverWidth) {
      coverWidth = config.minCoverWidth;
      isConstrained = true;
    } else if (rawWidth > config.maxCoverWidth) {
      coverWidth = config.maxCoverWidth;
      isConstrained = true;
    } else {
      coverWidth = rawWidth;
    }

    // 【步骤4】按 3:4 比例计算封面高度
    // 宽/高 = 3/4，所以 高 = 宽 * 4/3
    final coverHeight = coverWidth / config.coverAspectRatio;

    // 【步骤5】计算 GridView 的 childAspectRatio
    // item总高度 = 封面高度 + 标题区域高度
    // aspectRatio = 宽度 / 总高度
    final totalHeight = coverHeight + config.titleAreaHeight;
    final gridAspectRatio = coverWidth / totalHeight;

    return BookCoverSize(
      width: coverWidth,
      height: coverHeight,
      gridAspectRatio: gridAspectRatio,
      isConstrained: isConstrained,
    );
  }

  /// 便捷方法：从 BuildContext 获取 GridDelegate
  ///
  /// 使用示例：
  /// ```dart
  /// GridView.builder(
  ///   gridDelegate: BookshelfSizer.getGridDelegate(context),
  ///   ...
  /// )
  /// ```
  static SliverGridDelegateWithFixedCrossAxisCount getGridDelegate(
    BuildContext context, {
    BookshelfConfig? config,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final orientation = MediaQuery.orientationOf(context);

    final effectiveConfig = config ?? getConfigForDevice(screenWidth, orientation);
    final size = calculate(screenWidth, effectiveConfig);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: effectiveConfig.columnsPerPage,
      mainAxisSpacing: effectiveConfig.mainAxisSpacing,
      crossAxisSpacing: effectiveConfig.crossAxisSpacing,
      childAspectRatio: size.gridAspectRatio,
    );
  }

  /// 便捷方法：从 BuildContext 获取封面尺寸
  static BookCoverSize getSize(BuildContext context, {BookshelfConfig? config}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final orientation = MediaQuery.orientationOf(context);

    final effectiveConfig = config ?? getConfigForDevice(screenWidth, orientation);
    return calculate(screenWidth, effectiveConfig);
  }

  /// 调试信息
  static String debugInfo(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final orientation = MediaQuery.orientationOf(context);
    final config = getConfigForDevice(screenWidth, orientation);
    final size = calculate(screenWidth, config);

    return '''
╔══════════════════════════════════════╗
║       BookshelfSizer Debug Info       ║
╠══════════════════════════════════════╣
║ Screen Width:    ${screenWidth.toStringAsFixed(1).padLeft(8)} dp         ║
║ Orientation:     ${orientation.name.padRight(8)}            ║
║ Columns:         ${config.columnsPerPage.toString().padLeft(8)}            ║
║ Padding:         ${config.horizontalPadding.toStringAsFixed(1).padLeft(8)} dp         ║
║ H-Spacing:       ${config.crossAxisSpacing.toStringAsFixed(1).padLeft(8)} dp         ║
║ V-Spacing:       ${config.mainAxisSpacing.toStringAsFixed(1).padLeft(8)} dp         ║
╠══════════════════════════════════════╣
║ Cover Width:     ${size.width.toStringAsFixed(1).padLeft(8)} dp         ║
║ Cover Height:    ${size.height.toStringAsFixed(1).padLeft(8)} dp         ║
║ Grid Ratio:      ${size.gridAspectRatio.toStringAsFixed(3).padLeft(8)}            ║
║ Constrained:     ${size.isConstrained ? 'YES' : 'NO'.padLeft(8)}            ║
╚══════════════════════════════════════╝
''';
  }
}