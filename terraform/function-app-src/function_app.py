import azure.functions as func
import json
import logging

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="mcp", methods=["GET", "POST", "OPTIONS"])
def mcp_handler(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('MCP handler received request')
    
    # Handle CORS preflight
    if req.method == "OPTIONS":
        return func.HttpResponse(
            "",
            status_code=200,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Authorization, Content-Type",
            }
        )
    
    # Handle SSE request (GET)
    if req.method == "GET":
        # Return SSE headers for MCP initialization
        return func.HttpResponse(
            "data: {\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{}}\n\n",
            status_code=200,
            headers={
                "Content-Type": "text/event-stream",
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "Access-Control-Allow-Origin": "*",
            }
        )
    
    # Handle JSON-RPC request (POST)
    if req.method == "POST":
        try:
            req_body = req.get_json()
            method = req_body.get('method', '')
            request_id = req_body.get('id', 1)
            
            # Basic MCP responses
            if method == 'initialize':
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {
                        "protocolVersion": "2024-11-05",
                        "capabilities": {
                            "tools": {},
                            "prompts": {},
                            "resources": {}
                        },
                        "serverInfo": {
                            "name": "apim-mcp-server",
                            "version": "1.0.0"
                        }
                    }
                }
            elif method == 'tools/list':
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {
                        "tools": [
                            {
                                "name": "hello",
                                "description": "A simple hello world tool",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "name": {
                                            "type": "string",
                                            "description": "Name to greet"
                                        }
                                    }
                                }
                            }
                        ]
                    }
                }
            elif method == 'tools/call':
                params = req_body.get('params', {})
                tool_name = params.get('name', '')
                arguments = params.get('arguments', {})
                
                if tool_name == 'hello':
                    name = arguments.get('name', 'World')
                    response = {
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "result": {
                            "content": [
                                {
                                    "type": "text",
                                    "text": f"Hello, {name}!"
                                }
                            ]
                        }
                    }
                else:
                    response = {
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "error": {
                            "code": -32601,
                            "message": f"Unknown tool: {tool_name}"
                        }
                    }
            else:
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {}
                }
            
            return func.HttpResponse(
                json.dumps(response),
                status_code=200,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                }
            )
            
        except Exception as e:
            logging.error(f"Error processing request: {str(e)}")
            return func.HttpResponse(
                json.dumps({
                    "jsonrpc": "2.0",
                    "id": req_body.get('id', 1) if req_body else 1,
                    "error": {
                        "code": -32603,
                        "message": f"Internal error: {str(e)}"
                    }
                }),
                status_code=500,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                }
            )
    
    return func.HttpResponse(
        "Method not allowed",
        status_code=405
    )