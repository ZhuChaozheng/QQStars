import QtQuick 2.2

Item{
    id: root
    x: actualX+glowLeftWidth()
    y:actualY+glowTopHeight()
    
    width: item.width
    height: item.height
    property Item item: null
    onItemChanged: {
        item.parent=root
    }
    property int biasX: 0
    property int biasY: 0
    
    property alias glowRadius: rootItem.glowRadius
    property alias spread: rootItem.spread
    property alias color: rootItem.color
    property alias cornerRadius: rootItem.cornerRadius
    property alias cached: rootItem.cached
    property alias glowOpacity: rootItem.opacity
    property int actualX: 0
    property int actualY: 0

    function glowTopHeight() {
        return glowRadius+cornerRadius*0.6*(1-spread)-biasY
    }

    function glowBottomHeight() {
        return rootItem.y+rootItem.height+2*glowRadius+cornerRadius-glowTopHeight()-root.height
    }

    function glowLeftWidth() {
        return glowRadius+cornerRadius*0.6*(1-spread)-biasX
    }

    function glowRightWidth() {
        return rootItem.x+rootItem.width+2*glowRadius+cornerRadius-glowLeftWidth()-root.width
    }
    
    function actualWidth(){
        return glowLeftWidth()+rootItem.width+glowRightWidth()
    }
    function actualHeight(){
        return glowTopHeight()+rootItem.height+glowBottomHeight()
    }

    Item {
        id: rootItem
        
        property real glowRadius: 0.0
        property real spread: 0.0
        property color color: "white"
        property real cornerRadius: glowRadius
        property bool cached: false
    
        x: (biasX>0?biasX:0)
        y: (biasY>0?biasY:0)
        width: root.width-biasX
        height: root.height-biasY
        
        ShaderEffectSource {
             id: cacheItem
             anchors.fill: shaderItem
             visible: rootItem.cached
             smooth: true
             sourceItem: shaderItem
             live: true
             hideSource: visible
         }
    
        ShaderEffect {
            id: shaderItem
    
            x: (parent.width - width) / 2.0
            y: (parent.height - height) / 2.0
            width: parent.width + rootItem.glowRadius * 2 + cornerRadius * 2
            height: parent.height + rootItem.glowRadius * 2 + cornerRadius * 2
    
            function clampedCornerRadius() {
                var maxCornerRadius = Math.min(rootItem.width, rootItem.height) / 2 + glowRadius;
                return Math.max(0, Math.min(rootItem.cornerRadius, maxCornerRadius))
            }
    
            property color color: rootItem.color
            property real inverseSpread: 1.0 - rootItem.spread
            property real relativeSizeX: ((inverseSpread * inverseSpread) * rootItem.glowRadius + cornerRadius * 2.0) / width
            property real relativeSizeY: relativeSizeX * (width / height)
            property real spread: rootItem.spread / 2.0
            property real cornerRadius: clampedCornerRadius()
    
            fragmentShader: "
                uniform highp float qt_Opacity;
                uniform mediump float relativeSizeX;
                uniform mediump float relativeSizeY;
                uniform mediump float spread;
                uniform lowp vec4 color;
                varying highp vec2 qt_TexCoord0;
    
                highp float linearstep(highp float e0, highp float e1, highp float x) {
                    return clamp((x - e0) / (e1 - e0), 0.0, 1.0);
                }
    
                void main() {
                    lowp float alpha =
                        smoothstep(0.0, relativeSizeX, 0.5 - abs(0.5 - qt_TexCoord0.x)) *
                        smoothstep(0.0, relativeSizeY, 0.5 - abs(0.5 - qt_TexCoord0.y));
    
                    highp float spreadMultiplier = linearstep(spread, 1.0 - spread, alpha);
                    gl_FragColor = color * qt_Opacity * spreadMultiplier * spreadMultiplier;
                }
            "
        }
    }    
}