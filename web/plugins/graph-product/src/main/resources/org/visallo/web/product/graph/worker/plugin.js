define([
    'configuration/plugins/registry',
    'updeep',
    './snap',
], function(registry, updeep, snapPosition) {

    registry.registerExtension('org.visallo.store', {
        key: 'product',
        reducer: function(state, { type, payload }) {
            switch (type) {
                case 'PRODUCT_GRAPH_SET_POSITIONS': return updatePositions(state, payload);
                case 'PRODUCT_ADD_EDGE_IDS': return addEdges(state, payload);
            }

            return state;
        }
    })

    function addEdges(state, { productId, edges, workspaceId }) {
        const product = state.workspaces[workspaceId].products[productId];
        if (product && product.extendedData && product.extendedData.edges) {
            let newIndex = product.extendedData.edges.length;
            const byId = _.indexBy(product.extendedData.edges, 'edgeId')
            const update = _.object(_.compact(edges.map(edgeInfo => {
                if (edgeInfo.edgeId in byId) return;
                return [newIndex++, edgeInfo];
            })));

            return updeep.updateIn(`workspaces.${workspaceId}.products.${productId}.extendedData.edges`, update, state);
        }

        return state;
    }

    function updatePositions(state, { workspaceId, productId, updateVertices, snapToGrid }) {
        const product = state.workspaces[workspaceId].products[productId];

        if (product && product.extendedData && product.extendedData.vertices) {
            const updatedIds = [];
            const updated = updeep.updateIn(
                `workspaces.${workspaceId}.products.${productId}.extendedData.vertices.*`,
                function(vertexPosition) {
                    if (vertexPosition.id in updateVertices) {
                        const pos = updateVertices[vertexPosition.id];
                        updatedIds.push([vertexPosition.id]);
                        return {
                            id: vertexPosition.id,
                            pos: snapToGrid ? snapPosition(pos) : pos
                        }
                    }
                    return vertexPosition;
                },
                state
            );

            const additionalVertices = _.omit(updateVertices, updatedIds)
            if (!_.isEmpty(additionalVertices)) {
                var nextIndex = product.extendedData.vertices.length;
                const additions = _.object(_.map(additionalVertices, (pos, id) => {
                    return [nextIndex++, { id, pos }];
                }));

                return updeep.updateIn(
                    `workspaces.${workspaceId}.products.${productId}.extendedData.vertices`,
                    additions,
                    updated
                )
            }

            return updated;
        }

        return state;
    }
});
