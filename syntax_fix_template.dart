import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../core/theme/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/data_sync_service.dart';
import '../../data/models/study_session.dart';
import '../../core/services/firestore_service.dart';
import '../../data/services/calendar_service.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';

import 'package:uuid/uuid.dart';

import '../../core/utils/responsive_utils.dart';
import '../../core/widgets/responsive_dialog.dart';

import '../../core/services/app_blocking_service.dart';
import '../../data/services/app_blocking_settings_service.dart';
import 'package:usage_stats/usage_stats.dart';
import '../../core/migration/user_id_migration.dart';

/// **SYNTAX ERROR FIX TEMPLATE**
/// This is a corrected section for the dropdown item structure
/// Replace the problematic section in your timer_screen.dart around lines 1750-1820
/// 
/// CORRECT STRUCTURE:
/// Row(
///   children: [
///     // ... widgets ...
///   ], // <- This ] closes the children array that starts at line 1753
/// ),   // <- This ) closes the Row widget
/// 
/// The error is that line 1812 has ) instead of ]

Widget buildCorrectDropdownItem(CalendarEvent event, Subject subject, Task? task) {
  return DropdownMenuItem<CalendarEvent?>(
    value: event,
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color(int.parse(subject.color.replaceFirst('#', '0xff'))),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppStyles.spaceXS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Date badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.mutedForeground.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${event.startTime.day}/${event.startTime.month}',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppStyles.mutedForeground,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppStyles.spaceXS),
                    Text(
                      '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppStyles.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spaceXS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${event.durationMinutes}min',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppStyles.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (task != null) ...[
                      const SizedBox(width: AppStyles.spaceXS),
                      Expanded(
                        child: Text(
                          ' • ${task.title}',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppStyles.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ], // <- CORRECT: ] closes Row children array
                ), // <- CORRECT: ) closes SingleChildScrollView
              ), // <- CORRECT: ) closes SingleChildScrollView widget  
            ], // <- CORRECT: ] closes Column children array
          ), // <- CORRECT: ) closes Column widget
        ), // <- CORRECT: ) closes Expanded widget
      ], // <- CORRECT: ] closes main Row children array
    ), // <- CORRECT: ) closes main Row widget
  ); // <- CORRECT: ) closes DropdownMenuItem
}