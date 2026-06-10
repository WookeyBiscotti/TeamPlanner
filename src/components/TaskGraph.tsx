import { useEffect, useMemo } from 'react';
import {
  Background,
  Controls,
  MiniMap,
  ReactFlow,
  useEdgesState,
  useNodesState,
  type NodeTypes,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';

import type { TNodeField, WorkItem } from '../types/workItem';
import { buildGraphEdges, layoutGraph } from '../utils/buildGraph';
import { TaskNode } from './TaskNode';

const nodeTypes: NodeTypes = {
  task: TaskNode,
};

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
  const graphEdges = useMemo(() => buildGraphEdges(items), [items]);
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
      <div className="graph-legend">
        <span className="legend-item parent">родитель → ребёнок</span>
        <span className="legend-item blocker">блокер → задача</span>
        <span className="legend-count">{items.length} задач</span>
      </div>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        nodeTypes={nodeTypes}
        fitView
        onNodeClick={(_, node) => onSelect(Number.parseInt(node.id, 10))}
        onPaneClick={() => onSelect(null)}
      >
        <Background gap={16} />
        <Controls />
        <MiniMap pannable zoomable />
      </ReactFlow>
    </div>
  );
}
