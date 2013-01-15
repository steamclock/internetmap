//
//  MapDisplay.hpp
//  InternetMap
//


#ifndef InternetMap_MapDisplay_hpp
#define InternetMap_MapDisplay_hpp


#include "Types.hpp"
#include <memory>

class Lines;
class Camera;
class Nodes;
class Program;

class MapDisplay {
    void bindDefaultNodeUniforms(std::shared_ptr<Program> program);

    std::shared_ptr<Program> _nodeProgram;
    std::shared_ptr<Program> _selectedNodeProgram;
    std::shared_ptr<Program> _connectionProgram;

    float _displayScale;

public:
    MapDisplay();
    
    void setDisplayScale(float f) { _displayScale = f; }
    float getDisplayScale() { return _displayScale;}
    std::shared_ptr<Camera> camera;
    std::shared_ptr<Nodes> nodes;
    std::shared_ptr<Nodes> selectedNodes;
    std::shared_ptr<Lines> visualizationLines;
    std::shared_ptr<Lines> highlightLines;
    
    void update(TimeInterval currentTime);
    void draw(void);
};

#endif