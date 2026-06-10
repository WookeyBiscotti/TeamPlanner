import { useEffect, useMemo, useState } from 'react';
import {
  Background,
  Controls,
  MiniMap,
  ReactFlow,
  useEdgesState,
  useNodesState,
  type Node,
  type NodeTypes,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';

import {
  ALL_EDGE_KINDS,
  type EdgeKind,
  type TNodeField,
  type WorkItem,
} from '../types/workItem';
import {
  buildGraphEdges,
  filterGraphEdges,
  layoutGraph,
  type TaskNodeData,
} from '../utils/buildGraph';
import { LinkFilter } from './LinkFilter';
import { TaskNode } from './TaskNode';

const nodeTypes: NodeTypes = {
  task: TaskNode,
};

const MIN_ZOOM = 0.05;
const MAX_ZOOM = 2;

function minimapNodeColor(node: Node): string {
  const data = node.data as TaskNodeData;
  if (node.selected) return '#3b82f6';
  const state = data.item.fields['System.State'];
  if (state === 'Closed' || state === 'Removed') return '#64748b';
  if (state === 'Active' || state === 'In Progress') return '#22c55e';
  return '#cbd5e1';
}

interface TaskGraphProps {
  items: WorkItem[];
  nodeFields: TNodeField[];
  selectedId: number | null;
  onSelect: (id: number | null) => void;
}

export function TaskGraph({
  items,
  nodeFields,
  selectedId,
  onSelect,
}: TaskGraphProps) {
  const [visibleLinks, setVisibleLinks] = useState<Set<EdgeKind>>(
    () => new Set(ALL_EDGE_KINDS),
  );

  const allGraphEdges = useMemo(() => buildGraphEdges(items), [items]);
  const graphEdges = useMemo(
    () => filterGraphEdges(allGraphEdges, visibleLinks),
    [allGraphEdges, visibleLinks],
  );

  const edgeCounts = useMemo(() => {
    const counts: Partial<Record<EdgeKind, number>> = {};
    for (const edge of allGraphEdges) {
      counts[edge.kind] = (counts[edge.kind] ?? 0) + 1;
    }
    return counts;
  }, [allGraphEdges]);

  const layout = useMemo(
    () => layoutGraph(items, graphEdges),
    [items, graphEdges],
  );

  const [nodes, setNodes, onNodesChange] = useNodesState(layout.nodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(layout.edges);

  useEffect(() => {
    const next = layoutGraph(items, graphEdges);
    setNodes(
      next.nodes.map((node) => ({
        ...node,
        data: {
          ...node.data,
          fields: nodeFields,
        },
        selected: selectedId != null && node.id === String(selectedId),
      })),
    );
    setEdges(next.edges);
  }, [items, graphEdges, nodeFields, selectedId, setNodes, setEdges]);

  if (items.length === 0) {
    return (
      <div className="graph-empty">
        Загрузите задачи по Area или ID, чтобы увидеть граф связей
      </div>
    );
  }

  return (
    <div className="graph-panel">
      <div className="graph-toolbar">
        <LinkFilter
          visible={visibleLinks}
          onChange={setVisibleLinks}
          edgeCounts={edgeCounts}
        />
        <span className="legend-count">{items.length} задач</span>
      </div>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        nodeTypes={nodeTypes}
        minZoom={MIN_ZOOM}
        maxZoom={MAX_ZOOM}
        fitView
        fitViewOptions={{ padding: 0.2, maxZoom: 1 }}
        onNodeClick={(_, node) => onSelect(Number.parseInt(node.id, 10))}
        onPaneClick={() => onSelect(null)}
      >
        <Background gap={20} color="#cbd5e1" />
        <Controls showInteractive={false} />
        <MiniMap
          pannable
          zoomable
          nodeColor={minimapNodeColor}
          nodeStrokeColor="#0f172a"
          nodeStrokeWidth={2}
          maskColor="rgb(15 23 42 / 0.55)"
          maskStrokeColor="#475569"
          maskStrokeWidth={1}
          style={{
            background: '#1e293b',
            border: '1px solid #475569',
            borderRadius: 8,
          }}
        />
      </ReactFlow>
    </div>
  );
}
