// One Three.js instance shared by 3d-force-graph, three-spritetext and the custom node objects in
// xsl/client/3d-force-graph.xsl, which read all three from window
import * as THREE from 'three';
import ForceGraph3D from '3d-force-graph';
import SpriteText from 'three-spritetext';

Object.assign(window, { THREE, ForceGraph3D, SpriteText });
