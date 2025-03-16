import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/memory_model.dart';

class MediaCard extends StatefulWidget {
  final Media media;
  final Function(Media) onEdit;
  final Function() onDelete;

  const MediaCard({
    super.key,
    required this.media,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  _MediaCardState createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    descriptionController.text = widget.media.description;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Thumbnail
            widget.media.type == MediaType.image
                ? widget.media.url != null && widget.media.url!.startsWith('http')
                ? Image.network(
              widget.media.url!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Image.file(
              File(widget.media.url ?? ''),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(),

            // Description Field
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) {
                widget.media.description = value;
                widget.onEdit(widget.media);
              },
            ),
            const SizedBox(height: 10),

            // Delete Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    widget.onDelete();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
