import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app/theme/app_theme.dart';

void main() {
  testWidgets('Default text renders Amharic glyphs using Ethiopic font',
      (WidgetTester tester) async {
    const sampleText = 'መዝሙር ጓደኛ';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Text(sampleText),
          ),
        ),
      ),
    );

    final element = tester.element(find.text(sampleText));
    final defaultStyle = DefaultTextStyle.of(element).style;

    expect(
      defaultStyle.fontFamily,
      GoogleFonts.notoSansEthiopic().fontFamily,
    );
  });

  testWidgets('Dropdown fields inherit Ethiopic-supporting font',
      (WidgetTester tester) async {
    const items = ['ሙዚቃ'];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (context) => DropdownButtonFormField<String>(
                value: items.first,
                style: Theme.of(context).textTheme.titleMedium,
                items: items
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );

    expect(
      dropdown.style?.fontFamily,
      GoogleFonts.notoSansEthiopic().fontFamily,
    );
  });
}
