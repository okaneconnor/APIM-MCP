import azure.functions as func
import logging
import json
import os
import uuid
from typing import Dict, Any
from datetime import datetime, timezone, timedelta

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Configuration - get from environment variables
TENANT_ID = os.environ.get("TENANT_ID", "")
CLIENT_ID = os.environ.get("CLIENT_ID", "")

# In-memory storage for OAuth state data (in production, use Redis or Cosmos DB)
oauth_state_storage = {}

@app.route(route="mcp", methods=["GET", "POST", "OPTIONS"])
async def mcp_handler(req: func.HttpRequest) -> func.HttpResponse:
    """MCP handler for streamable HTTP transport"""
    logging.info(f'MCP handler accessed with method: {req.method}')
    
    # Handle CORS preflight
    if req.method == "OPTIONS":
        return func.HttpResponse(
            "",
            status_code=200,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "*"
            }
        )
    
    # Handle POST requests (JSON-RPC for MCP)
    if req.method == "POST":
        try:
            body = req.get_json()
            method = body.get('method')
            request_id = body.get('id', 1)
            params = body.get('params', {})
            
            logging.info(f"MCP method called: {method}")
            
            # Handle different MCP methods
            if method == 'initialize':
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {
                        "protocolVersion": "2024-11-05",
                        "capabilities": {
                            "tools": {
                                "listTools": {},
                                "callTool": {}
                            }
                        },
                        "serverInfo": {
                            "name": "azure-mcp-server",
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
                                "name": "get_azure_info",
                                "description": "Get Azure subscription and tenant information",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {},
                                    "additionalProperties": False
                                }
                            },
                            {
                                "name": "echo_message",
                                "description": "Echo back a message",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "message": {
                                            "type": "string",
                                            "description": "Message to echo"
                                        }
                                    },
                                    "required": ["message"],
                                    "additionalProperties": False
                                }
                            }
                        ]
                    }
                }
            
            elif method == 'tools/call':
                tool_name = params.get('name')
                tool_args = params.get('arguments', {})
                
                if tool_name == "get_azure_info":
                    response = {
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "result": {
                            "content": [
                                {
                                    "type": "text",
                                    "text": json.dumps({
                                        "tenant_id": TENANT_ID,
                                        "client_id": CLIENT_ID,
                                        "timestamp": datetime.now(timezone.utc).isoformat(),
                                        "message": "Azure MCP Server is running!"
                                    }, indent=2)
                                }
                            ]
                        }
                    }
                
                elif tool_name == "echo_message":
                    message = tool_args.get('message', '')
                    response = {
                        "jsonrpc": "2.0",
                        "id": request_id,
                        "result": {
                            "content": [
                                {
                                    "type": "text",
                                    "text": f"Echo: {message}"
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
                    "error": {
                        "code": -32601,
                        "message": f"Method not found: {method}"
                    }
                }
            
            return func.HttpResponse(
                json.dumps(response),
                status_code=200,
                mimetype="application/json",
                headers={
                    "Access-Control-Allow-Origin": "*",
                    "Content-Type": "application/json"
                }
            )
            
        except Exception as e:
            logging.error(f"Error processing request: {str(e)}")
            return func.HttpResponse(
                json.dumps({
                    "jsonrpc": "2.0",
                    "id": request_id if 'request_id' in locals() else 1,
                    "error": {
                        "code": -32603,
                        "message": "Internal error",
                        "data": str(e)
                    }
                }),
                status_code=200,
                mimetype="application/json"
            )
    
    # Handle GET requests (initial connection test)
    elif req.method == "GET":
        return func.HttpResponse(
            json.dumps({
                "status": "ready",
                "server": "azure-mcp-server",
                "version": "1.0.0",
                "transport": "streamable-http"
            }),
            status_code=200,
            mimetype="application/json",
            headers={
                "Access-Control-Allow-Origin": "*"
            }
        )
    
    # Default response for unsupported methods
    return func.HttpResponse(
        json.dumps({"error": "Method not supported"}),
        status_code=405,
        mimetype="application/json"
    )

@app.route(route="health", methods=["GET"])
async def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint"""
    return func.HttpResponse(
        json.dumps({"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}),
        status_code=200,
        mimetype="application/json"
    )

@app.route(route="oauth-state", methods=["GET", "POST"])
async def oauth_state_handler(req: func.HttpRequest) -> func.HttpResponse:
    """OAuth state storage handler"""
    logging.info(f'OAuth state handler accessed with method: {req.method}')

    try:
        if req.method == 'POST':
            # Store state data
            req_body = req.get_json()
            if not req_body:
                return func.HttpResponse(
                    json.dumps({"error": "Missing request body"}),
                    status_code=400,
                    mimetype="application/json"
                )
            
            state_id = str(uuid.uuid4())
            oauth_state_storage[state_id] = {
                'data': req_body,
                'expires': datetime.now(timezone.utc) + timedelta(hours=1)
            }
            
            logging.info(f"Stored state {state_id} with data: {req_body}")
            
            return func.HttpResponse(
                json.dumps({"state_id": state_id}),
                status_code=200,
                mimetype="application/json"
            )
            
        elif req.method == 'GET':
            # Retrieve state data
            state_id = req.params.get('state_id')
            if not state_id:
                return func.HttpResponse(
                    json.dumps({"error": "Missing state_id parameter"}),
                    status_code=400,
                    mimetype="application/json"
                )
            
            # Clean expired entries
            current_time = datetime.now(timezone.utc)
            expired_keys = [k for k, v in oauth_state_storage.items() 
                          if v['expires'] < current_time]
            for key in expired_keys:
                del oauth_state_storage[key]
                
            logging.info(f"Looking up state {state_id}. Available keys: {list(oauth_state_storage.keys())}")
            
            if state_id not in oauth_state_storage:
                return func.HttpResponse(
                    json.dumps({"error": "State not found or expired"}),
                    status_code=404,
                    mimetype="application/json"
                )
            
            state_data = oauth_state_storage[state_id]['data']
            # Remove from storage after retrieval (one-time use)
            del oauth_state_storage[state_id]
            
            logging.info(f"Retrieved and deleted state {state_id}: {state_data}")
            
            return func.HttpResponse(
                json.dumps(state_data),
                status_code=200,
                mimetype="application/json"
            )
            
        else:
            return func.HttpResponse(
                json.dumps({"error": "Method not allowed"}),
                status_code=405,
                mimetype="application/json"
            )
            
    except Exception as e:
        logging.error(f"Error in OAuth state handler: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error", "details": str(e)}),
            status_code=500,
            mimetype="application/json"
        )