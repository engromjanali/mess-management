import 'package:flutter/material.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/mess_details_entity.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/copyable_info_row.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_section_card.dart';

/// The mess's own address, email and phone (tap to copy).
class MessContactCard extends StatelessWidget {
  const MessContactCard({required this.mess, super.key});

  final MessDetailsEntity mess;

  @override
  Widget build(BuildContext context) {
    final notProvided = context.local.notProvided;
    return MessSectionCard(
      title: context.local.messContact,
      icon: Icons.contact_mail_rounded,
      child: Column(
        children: [
          CopyableInfoRow(icon: Icons.location_on_rounded, label: context.local.address, value: mess.address, emptyLabel: notProvided),
          CopyableInfoRow(icon: Icons.email_rounded, label: context.local.email, value: mess.email, emptyLabel: notProvided),
          CopyableInfoRow(icon: Icons.phone_rounded, label: context.local.phone, value: mess.phone, emptyLabel: notProvided),
        ],
      ),
    );
  }
}
