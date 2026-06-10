import dagre from 'dagre';
import { MarkerType, type Edge, type Node } from '@xyflow/react';

import { extractAllRelationEdges } from '../api/relations';
import {
  relationConfig,
  type EdgeKind,
  type GraphEdge,
  type TNodeField,
  type WorkItem,
} from '../types/workItem';

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

  const addEdge = (
    source: number,
    target: number,
    kind: EdgeKind,
    rel: string,
  ) => {
    if (!ids.has(source) || !ids.has(target) || source === target) return;
    const id = `${kind}:${source}->${target}`;
    if (seen.has(id)) return;
    seen.add(id);
    edges.push({
      id,
      source: String(source),
      target: String(target),
      kind,
      rel,
    });
  };

  for (const item of items) {
    for (const parsed of extractAllRelationEdges(item)) {
      addEdge(parsed.source, parsed.target, parsed.kind, parsed.rel);
    }
  }

  return edges;
}

export function filterGraphEdges(
  edges: GraphEdge[],
  visibleKinds: Set<EdgeKind>,
): GraphEdge[] {
  return edges.filter((edge) => visibleKinds.has(edge.kind));
}

export function layoutGraph(
  items: WorkItem[],
  graphEdges: GraphEdge[],
): { nodes: Node<TaskNodeData>[]; edges: Edge[] } {
  const g = new dagre.graphlib.Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({
    rankdir: 'TB',
    nodesep: 90,
    ranksep: 110,
    edgesep: 50,
    marginx: 40,
    marginy: 40,
  });

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

  const edges: Edge[] = graphEdges.map((edge) => {
    const config = relationConfig(edge.kind);
    return {
      id: edge.id,
      source: edge.source,
      target: edge.target,
      type: 'straight',
      animated: edge.kind === 'dependency' || edge.kind === 'remote-dependency',
      style: {
        stroke: config.color,
        strokeWidth: edge.kind === 'parent-child' ? 2 : 2.5,
      },
      markerEnd: {
        type: MarkerType.ArrowClosed,
        color: config.color,
        width: 18,
        height: 18,
      },
      label: config.shortLabel,
      labelStyle: { fill: config.color, fontSize: 10, fontWeight: 500 },
      labelBgStyle: { fill: '#ffffff', fillOpacity: 0.85 },
      labelBgPadding: [4, 6] as [number, number],
      labelBgBorderRadius: 4,
    };
  });

  return { nodes, edges };
}
