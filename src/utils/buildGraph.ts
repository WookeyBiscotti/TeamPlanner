import dagre from 'dagre';
import { MarkerType, type Edge, type Node } from '@xyflow/react';

import { extractBlockerIds, extractParentId } from '../api/tfs';
import type { EdgeKind, GraphEdge, TNodeField, WorkItem } from '../types/workItem';

export interface TaskNodeData extends Record<string, unknown> {
  item: WorkItem;
  fields: TNodeField[];
  selected: boolean;
}

const NODE_WIDTH = 260;
const NODE_HEIGHT = 120;

export function buildGraphEdges(items: WorkItem[]): GraphEdge[] {
  const ids = new Set(items.map((item) => item.id));
  const edges: GraphEdge[] = [];
  const seen = new Set<string>();

  const addEdge = (source: number, target: number, kind: EdgeKind) => {
    if (!ids.has(source) || !ids.has(target) || source === target) return;
    const id = `${kind}:${source}->${target}`;
    if (seen.has(id)) return;
    seen.add(id);
    edges.push({
      id,
      source: String(source),
      target: String(target),
      kind,
    });
  };

  for (const item of items) {
    const parentId = extractParentId(item);
    if (parentId != null) {
      addEdge(parentId, item.id, 'parent');
    }

    for (const blockerId of extractBlockerIds(item)) {
      addEdge(blockerId, item.id, 'blocker');
    }
  }

  return edges;
}

export function layoutGraph(
  items: WorkItem[],
  graphEdges: GraphEdge[],
): { nodes: Node<TaskNodeData>[]; edges: Edge[] } {
  const g = new dagre.graphlib.Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({ rankdir: 'TB', nodesep: 48, ranksep: 72 });

  for (const item of items) {
    g.setNode(String(item.id), { width: NODE_WIDTH, height: NODE_HEIGHT });
  }

  for (const edge of graphEdges) {
    g.setEdge(edge.source, edge.target);
  }

  dagre.layout(g);

  const nodes: Node<TaskNodeData>[] = items.map((item) => {
    const node = g.node(String(item.id));
    return {
      id: String(item.id),
      type: 'task',
      position: {
        x: (node?.x ?? 0) - NODE_WIDTH / 2,
        y: (node?.y ?? 0) - NODE_HEIGHT / 2,
      },
      data: {
        item,
        fields: [],
        selected: false,
      },
    };
  });

  const edges: Edge[] = graphEdges.map((edge) => ({
    id: edge.id,
    source: edge.source,
    target: edge.target,
    type: 'smoothstep',
    animated: edge.kind === 'blocker',
    style: {
      stroke: edge.kind === 'blocker' ? '#dc2626' : '#64748b',
      strokeWidth: edge.kind === 'blocker' ? 2.5 : 2,
    },
    markerEnd: {
      type: MarkerType.ArrowClosed,
      color: edge.kind === 'blocker' ? '#dc2626' : '#64748b',
    },
    label: edge.kind === 'blocker' ? 'блокер' : undefined,
    labelStyle: { fill: '#dc2626', fontSize: 10 },
  }));

  return { nodes, edges };
}
