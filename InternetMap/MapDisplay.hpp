//
//  MapDisplay.hpp
//  InternetMap
//

#include "Types.hpp"

class Lines;
class Camera;
class Nodes;
class Program;

class MapDisplay {
    void bindDefaultNodeUniforms(shared_ptr<Program> program);

    shared_ptr<Program> _nodeProgram;
    shared_ptr<Program> _selectedNodeProgram;
    shared_ptr<Program> _connectionProgram;

    float _displayScale;

public:
    MapDisplay();
    
    void setDisplayScale(float f) { _displayScale = f; }
    
    shared_ptr<Camera> camera;
    shared_ptr<Nodes> nodes;
    shared_ptr<Nodes> selectedNodes;
    shared_ptr<Lines> visualizationLines;
    shared_ptr<Lines> highlightLines;
    
    void update(TimeInterval currentTime);
    void draw(void);
};
