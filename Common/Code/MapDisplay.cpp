//
//  MapDisplay.cpp
//  InternetMap
//

#include "MapDisplay.hpp"
#include "Camera.hpp"
#include "DisplayLines.hpp"
#include "DisplayNodes.hpp"
#include "Program.hpp"
#include "OpenGL.hpp"

float gDisplayScale = 1.0f;

MapDisplay::MapDisplay() :
    _nodeProgram(new Program("node", "node", VERTEX_NODE)),
    _blendNodeProgram(new Program("node", "nodeBlend", VERTEX_BLEND_NODE)),
    _selectedNodeProgram(new Program("selectedNode", "node", VERTEX_NODE)),
    _connectionProgram (new Program("line",VERTEX_LINE)),
    nodes(new DisplayNodes(0)),
    targetNodes(new DisplayNodes(0)),
    _displayScale(1.0f),
    camera(new Camera()),
    _startBlend(0.0f),
    _endBlend(0.0f),
    _pendingBlendTime(0.0f)
{
    InitOpenGLExtensions();
}

void MapDisplay::update(TimeInterval currentTime) {
    if(_pendingBlendTime != 0.0f) {
        _startBlend = currentTime;
        _endBlend = currentTime + _pendingBlendTime;
        _pendingBlendTime = 0.0f;
    }
    _currentTime = currentTime;
    camera->update(currentTime);
}

void MapDisplay::bindDefaultNodeUniforms(shared_ptr<Program> program) {
    Matrix4 mv = camera->currentModelView();
    Matrix4 p = camera->currentProjection();
    glUniformMatrix4fv(program->uniformForName("modelViewMatrix"), 1, 0, reinterpret_cast<float*>(&mv));
    glUniformMatrix4fv(program->uniformForName("projectionMatrix"), 1, 0, reinterpret_cast<float*>(&p));
    glUniform1f(program->uniformForName("maxSize"), _displayScale * camera->getSubregionScale() * 300.0f); // Largest size to render a node. May be too large for slow devices
    glUniform1f(program->uniformForName("screenWidth"), _displayScale * camera->displayWidth());
    glUniform1f(program->uniformForName("screenHeight"), _displayScale * camera->displayHeight());
}

void MapDisplay::draw(void)
{
    gDisplayScale = _displayScale;
    
#ifdef BUILD_MAC
    static GLuint vao = 0;
    if(vao == 0) {
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);
    }
    
    glEnable(GL_PROGRAM_POINT_SIZE);
#endif
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f); //Visualization background color
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnable(GL_DEPTH_TEST); //enable z testing and writing
    glEnable(GL_BLEND);

    glEnable(GL_POINT_SPRITE_OES);
    
    glEnable(GL_LINE_SMOOTH);
    
    if (selectedNodes) {
        _selectedNodeProgram->bind();
        bindDefaultNodeUniforms(_selectedNodeProgram);
        
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        selectedNodes->display();
    }
    
    glBlendFunc(GL_ONE, GL_ONE);
    glDepthMask(GL_FALSE); //disable z writing only

    if (nodes) {
        if(_startBlend != _endBlend) {
            float blend = (_currentTime - _startBlend) / (_endBlend - _startBlend);
            if(blend >= 1.0f) {
                blend = 1.0f;
            }
            
            _blendNodeProgram->bind();
            bindDefaultNodeUniforms(_blendNodeProgram);
            glUniform1f(_blendNodeProgram->uniformForName("minSize"), 2.0f);
            glUniform1f(_blendNodeProgram->uniformForName("blend"), blend);
            targetNodes->bindBlendTarget();
            nodes->display();
            
            glDisableVertexAttribArray(ATTRIB_POSITIONTARGET);
            glDisableVertexAttribArray(ATTRIB_SIZETARGET);
            glDisableVertexAttribArray(ATTRIB_COLORTARGET);
            
            if(blend >= 1.0f) {
                _startBlend = _endBlend = 0.0f;
                shared_ptr<DisplayNodes> tmp = nodes;
                nodes = targetNodes;
                targetNodes = tmp;
            }
        }
        else {
            _nodeProgram->bind();
            bindDefaultNodeUniforms(_nodeProgram);
            glUniform1f(_nodeProgram->uniformForName("minSize"), 2.0f);
            nodes->display();
        }
    }

    Matrix4 mvp = camera->currentModelViewProjection();

    if(visualizationLines || highlightLines) {
        _connectionProgram->bind();
        glUniformMatrix4fv(_connectionProgram->uniformForName("modelViewProjectionMatrix"), 1, 0, reinterpret_cast<float*>(&mvp));
    }
    
    if(visualizationLines) { 
        visualizationLines->display();
    }

    if(highlightLines) {
        highlightLines->display();
    }
    
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
    
}

void MapDisplay::startBlend(TimeInterval blend) {
    _pendingBlendTime = blend;
}

