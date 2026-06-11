import { MarkerType, type Edge, type Node } from '@xyflow/react';

import type { LayoutAlgorithm } from '../types/layout';
import { extractAllRelationEdges } from '../api/relations';
import {
  relationConfig,
  type EdgeKind,
  type GraphEdge,
  type TNodeField,
  type WorkItem,
} from '../types/workItem';
import { computeNodePositions } from './layoutAlgorithms';

export interface TaskNodeData extends Record<string, unknown> {
  item: WorkItem;
  fields: TNodeField[];
  selected: boolean;
  expanded: boolean;
  colorByStatus: boolean;
  statusColors: Record<string, string>;
  highlightColor: string | null;
  onToggleExpand?: (id: number) => void;
  onShowRaw?: (id: number) => void;
}

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

function buildFlowEdges(graphEdges: GraphEdge[]): Edge[] {
  return graphEdges.map((edge) => {
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
}

export function layoutGraph(
  items: WorkItem[],
  graphEdges: GraphEdge[],
  algorithm: LayoutAlgorithm,
  options: {
    colorByStatus: boolean;
    statusColors: Record<string, string>;
  },
): { nodes: Node<TaskNodeData>[]; edges: Edge[] } {
  const nodeIds = items.map((item) => String(item.id));
  const positions = computeNodePositions(nodeIds, graphEdges, algorithm);

  const nodes: Node<TaskNodeData>[] = items.map((item) => {
    const id = String(item.id);
    const position = positions.get(id) ?? { x: 0, y: 0 };
    return {
      id,
      type: 'task',
      position,
      data: {
        item,
        fields: [],
        selected: false,
        expanded: false,
        colorByStatus: options.colorByStatus,
        statusColors: options.statusColors,
        highlightColor: null,
      },
    };
  });

  return { nodes, edges: buildFlowEdges(graphEdges) };
}
