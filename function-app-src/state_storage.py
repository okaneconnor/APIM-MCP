import json
import uuid
import logging
from datetime import datetime, timedelta
from azure.functions import HttpRequest, HttpResponse

# In-memory storage for state data (in production, use Redis or Cosmos DB)
oauth_state_storage = {}

def main(req: HttpRequest) -> HttpResponse:
    logging.info('OAuth state storage function processed a request.')

    try:
        method = req.method
        
        if method == 'POST':
            # Store state data
            req_body = req.get_json()
            if not req_body:
                return HttpResponse(
                    json.dumps({"error": "Missing request body"}),
                    status_code=400,
                    mimetype="application/json"
                )
            
            state_id = str(uuid.uuid4())
            oauth_state_storage[state_id] = {
                'data': req_body,
                'expires': datetime.utcnow() + timedelta(hours=1)
            }
            
            return HttpResponse(
                json.dumps({"state_id": state_id}),
                status_code=200,
                mimetype="application/json"
            )
            
        elif method == 'GET':
            # Retrieve state data
            state_id = req.params.get('state_id')
            if not state_id:
                return HttpResponse(
                    json.dumps({"error": "Missing state_id parameter"}),
                    status_code=400,
                    mimetype="application/json"
                )
            
            # Clean expired entries
            current_time = datetime.utcnow()
            expired_keys = [k for k, v in oauth_state_storage.items() 
                          if v['expires'] < current_time]
            for key in expired_keys:
                del oauth_state_storage[key]
            
            if state_id not in oauth_state_storage:
                return HttpResponse(
                    json.dumps({"error": "State not found or expired"}),
                    status_code=404,
                    mimetype="application/json"
                )
            
            state_data = oauth_state_storage[state_id]['data']
            # Remove from storage after retrieval (one-time use)
            del oauth_state_storage[state_id]
            
            return HttpResponse(
                json.dumps(state_data),
                status_code=200,
                mimetype="application/json"
            )
            
        else:
            return HttpResponse(
                json.dumps({"error": "Method not allowed"}),
                status_code=405,
                mimetype="application/json"
            )
            
    except Exception as e:
        logging.error(f"Error in state storage: {str(e)}")
        return HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json"
        )