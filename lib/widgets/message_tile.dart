import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageTile extends StatefulWidget {
  final String message;
  final String sender;
  final bool sentByMe;
  final DateTime time;

  const MessageTile(
      {super.key,
      required this.message,
      required this.sender,
      required this.sentByMe,
      required this.time});

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  String timeSent = "";

  setTimeSet() {
    setState(() {
      timeSent = DateFormat.jm().format(widget.time);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setTimeSet();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: widget.sentByMe ? 0 : 16,
        right: widget.sentByMe ? 16 : 0,
      ),
      alignment: widget.sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: widget.sentByMe
            ? const EdgeInsets.only(left: 30)
            : const EdgeInsets.only(right: 30),
        padding:
            const EdgeInsets.only(top: 17, bottom: 17, left: 20, right: 20),
        decoration: BoxDecoration(
          borderRadius: widget.sentByMe
              ? const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
          color: widget.sentByMe
              ? Theme.of(context).primaryColor
              : Colors.orange[700],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sender.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.sentByMe ? Container() : Text("$timeSent "),
                SizedBox(width: widget.sentByMe ? 0 : 10),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: widget.sentByMe ? 10 : 0),
                widget.sentByMe
                    ? Text(
                        "$timeSent ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      )
                    : Container(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
