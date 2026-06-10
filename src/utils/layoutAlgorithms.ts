import {
  forceCenter,
  forceCollide,
  forceLink,
  forceManyBody,
  forceSimulation,
} from 'd3-force';
import dagre from 'dagre';

import type { LayoutAlgorithm } from '../types/layout';
import type { GraphEdge } from '../types/workItem';

export const NODE_WIDTH = 260;
export const NODE_HEIGHT = 120;

export interface LayoutPosition {
  x: number;
  y: number;
}

function layoutDagre(
  nodeIds: string[],
  graphEdges: GraphEdge[],
  rankdir: 'TB' | 'LR',
): Map<string, LayoutPosition> {
  const g = new dagre.graphlib.Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({
    rankdir,
    nodesep: 90,
    ranksep: 110,
    edgesep: 50,
    marginx: 40,
    marginy: 40,
  });

  for (const id of nodeIds) {
    g.setNode(id, { width: NODE_WIDTH, height: NODE_HEIGHT });
  }

  for (const edge of graphEdges) {
    g.setEdge(edge.source, edge.target);
  }

  dagre.layout(g);

  const positions = new Map<string, LayoutPosition>();
  for (const id of nodeIds) {
    const node = g.node(id);
    positions.set(id, {
      x: (node?.x ?? 0) - NODE_WIDTH / 2,
      y: (node?.y ?? 0) - NODE_HEIGHT / 2,
    });
  }
  return positions;
}

function layoutForce(
  nodeIds: string[],
  graphEdges: GraphEdge[],
): Map<string, LayoutPosition> {
  const simNodes = nodeIds.map((id) => ({
    id,
    x: Math.random() * 400 - 200,
    y: Math.random() * 400 - 200,
  }));

  const nodeById = new Map(simNodes.map((node) => [node.id, node]));
  const links = graphEdges
    .map((edge) => {
      const source = nodeById.get(edge.source);
      const target = nodeById.get(edge.target);
      if (!source || !target) return null;
      return { source, target };
    })
    .filter((link): link is { source: (typeof simNodes)[0]; target: (typeof simNodes)[0] } =>
      link != null,
    );

  const spread = Math.max(320, Math.sqrt(nodeIds.length) * 140);
  const simulation = forceSimulation(simNodes)
    .force(
      'link',
      forceLink(links)
        .id((node) => (node as (typeof simNodes)[0]).id)
        .distance(180)
        .strength(0.6),
    )
    .force('charge', forceManyBody().strength(-520))
    .force('center', forceCenter(0, 0))
    .force(
      'collide',
      forceCollide().radius(Math.max(NODE_WIDTH, NODE_HEIGHT) * 0.55),
    )
    .stop();

  const ticks = Math.min(500, 120 + nodeIds.length * 8);
  for (let i = 0; i < ticks; i += 1) {
    simulation.tick();
  }

  const positions = new Map<string, LayoutPosition>();
  for (const node of simNodes) {
    positions.set(node.id, {
      x: (node.x ?? 0) - NODE_WIDTH / 2,
      y: (node.y ?? 0) - NODE_HEIGHT / 2,
    });
  }

  // Центрируем результат вокруг начала координат с небольшим запасом
  if (positions.size > 0) {
    let minX = Infinity;
    let minY = Infinity;
    for (const pos of positions.values()) {
      minX = Math.min(minX, pos.x);
      minY = Math.min(minY, pos.y);
    }
    const offsetX = -minX + spread * 0.1;
    const offsetY = -minY + spread * 0.1;
    for (const [id, pos] of positions) {
      positions.set(id, { x: pos.x + offsetX, y: pos.y + offsetY });
    }
  }

  return positions;
}

function layoutRadial(
  nodeIds: string[],
  graphEdges: GraphEdge[],
): Map<string, LayoutPosition> {
  const inDegree = new Map<string, number>();
  const adjacency = new Map<string, string[]>();

  for (const id of nodeIds) {
    inDegree.set(id, 0);
    adjacency.set(id, []);
  }

  for (const edge of graphEdges) {
    if (!inDegree.has(edge.target)) continue;
    inDegree.set(edge.target, (inDegree.get(edge.target) ?? 0) + 1);
    adjacency.get(edge.source)?.push(edge.target);
  }

  const roots = nodeIds.filter((id) => (inDegree.get(id) ?? 0) === 0);
  const startNodes = roots.length > 0 ? roots : [nodeIds[0]];

  const level = new Map<string, number>();
  const queue = [...startNodes];
  for (const id of startNodes) level.set(id, 0);

  while (queue.length > 0) {
    const current = queue.shift()!;
    const currentLevel = level.get(current) ?? 0;
    for (const next of adjacency.get(current) ?? []) {
      if (level.has(next)) continue;
      level.set(next, currentLevel + 1);
      queue.push(next);
    }
  }

  let maxLevel = 0;
  const byLevel = new Map<number, string[]>();
  for (const id of nodeIds) {
    const nodeLevel = level.get(id) ?? maxLevel + 1;
    maxLevel = Math.max(maxLevel, nodeLevel);
    if (!byLevel.has(nodeLevel)) byLevel.set(nodeLevel, []);
    byLevel.get(nodeLevel)!.push(id);
  }

  const positions = new Map<string, LayoutPosition>();
  const levelGap = 220;
  const nodeGap = NODE_WIDTH + 40;

  for (const [nodeLevel, ids] of byLevel) {
    const radius = nodeLevel === 0 ? 0 : nodeLevel * levelGap;
    const count = ids.length;
    ids.forEach((id, index) => {
      if (radius === 0) {
        const offset = (index - (count - 1) / 2) * nodeGap;
        positions.set(id, { x: offset, y: 0 });
        return;
      }
      const angle = (2 * Math.PI * index) / count - Math.PI / 2;
      positions.set(id, {
        x: Math.cos(angle) * radius - NODE_WIDTH / 2,
        y: Math.sin(angle) * radius - NODE_HEIGHT / 2,
      });
    });
  }

  return positions;
}

function layoutGrid(nodeIds: string[]): Map<string, LayoutPosition> {
  const sorted = [...nodeIds].sort((a, b) => Number.parseInt(a, 10) - Number.parseInt(b, 10));
  const columns = Math.max(1, Math.ceil(Math.sqrt(sorted.length)));
  const gapX = NODE_WIDTH + 48;
  const gapY = NODE_HEIGHT + 48;

  const positions = new Map<string, LayoutPosition>();
  sorted.forEach((id, index) => {
    const col = index % columns;
    const row = Math.floor(index / columns);
    positions.set(id, { x: col * gapX, y: row * gapY });
  });
  return positions;
}

export function computeNodePositions(
  nodeIds: string[],
  graphEdges: GraphEdge[],
  algorithm: LayoutAlgorithm,
): Map<string, LayoutPosition> {
  if (nodeIds.length === 0) return new Map();

  switch (algorithm) {
    case 'dagre-lr':
      return layoutDagre(nodeIds, graphEdges, 'LR');
    case 'force':
      return layoutForce(nodeIds, graphEdges);
    case 'radial':
      return layoutRadial(nodeIds, graphEdges);
    case 'grid':
      return layoutGrid(nodeIds);
    case 'dagre-tb':
    default:
      return layoutDagre(nodeIds, graphEdges, 'TB');
  }
}
