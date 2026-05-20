import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../models/task_item.dart';

/// Synthetic root so graphview includes every task (orphans have no edges otherwise).
const String relationsGraphHubId = '__relations_hub__';

class RelationsGraphData {
  const RelationsGraphData({
    required this.graph,
    required this.tasksById,
  });

  final Graph graph;
  final Map<String, TaskItem> tasksById;
}

/// Builds a directed graph: parent → child (hierarchy), blocker → task (dependencies).
RelationsGraphData buildRelationsGraph({
  required List<TaskItem> tasks,
  required Color parentEdgeColor,
  required Color blockerEdgeColor,
}) {
  final graph = Graph();
  final tasksById = {for (final t in tasks) t.id: t};
  final ids = tasksById.keys.toSet();

  final parentPaint = Paint()
    ..color = parentEdgeColor
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  final blockerPaint = Paint()
    ..color = blockerEdgeColor
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke;

  for (final task in tasks) {
    final parentId = task.parentId;
    if (parentId != null && ids.contains(parentId)) {
      graph.addEdge(Node.Id(parentId), Node.Id(task.id), paint: parentPaint);
    }
  }

  for (final task in tasks) {
    final destination = Node.Id(task.id);
    for (final blockerId in task.blockedByIds) {
      if (!ids.contains(blockerId)) continue;
      final source = Node.Id(blockerId);
      final existing = graph.getEdgeBetween(source, destination);
      if (existing != null) {
        existing.paint = blockerPaint;
      } else {
        graph.addEdge(source, destination, paint: blockerPaint);
      }
    }
  }

  for (final task in tasks) {
    final node = Node.Id(task.id);
    if (!graph.nodes.any((n) => n.key == node.key)) {
      graph.addNode(node);
    }
  }

  _connectHubToRoots(graph, ids, parentEdgeColor);

  return RelationsGraphData(graph: graph, tasksById: tasksById);
}

/// graphview's layout only includes nodes reachable via edges; link every root to a hub.
void _connectHubToRoots(Graph graph, Set<String> taskIds, Color hubEdgeColor) {
  final hub = Node.Id(relationsGraphHubId);
  if (!graph.nodes.any((n) => n.key == hub.key)) {
    graph.addNode(hub);
  }

  final hubPaint = Paint()
    ..color = hubEdgeColor.withValues(alpha: 0)
    ..strokeWidth = 0
    ..style = PaintingStyle.stroke;

  final hasIncoming = <String>{};
  for (final edge in graph.edges) {
    final destId = edge.destination.key?.value;
    if (destId is String && destId != relationsGraphHubId) {
      hasIncoming.add(destId);
    }
  }

  for (final taskId in taskIds) {
    if (taskId == relationsGraphHubId) continue;
    if (hasIncoming.contains(taskId)) continue;
    final taskNode = Node.Id(taskId);
    if (graph.getEdgeBetween(hub, taskNode) == null) {
      graph.addEdge(hub, taskNode, paint: hubPaint);
    }
  }
}

String relationsGraphSignature(List<TaskItem> tasks) {
  final buffer = StringBuffer();
  for (final t in tasks) {
    buffer
      ..write(t.id)
      ..write(':')
      ..write(t.parentId)
      ..write(':')
      ..write(t.blockedByIds.join(','))
      ..write(';');
  }
  return buffer.toString();
}
