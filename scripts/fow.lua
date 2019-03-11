--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

--[[
Fog of War considerations and plan:

I have been looking into rudimentary dynamic lighting (which would no doubt take a number of weeks to finish if I were to push ahead). So something similar to what I found here while searching the forums: https://www.youtube.com/watch?v=Xj3FwXkJ_jU
What I have so far is that I've figured out how to accomplish this in broad strokes, both from a what we have available to work with to the math involved. So I have a rough outline development pipeline for this and I've started writing code to accomplish this to some degree of success so far, including creating the additional graphics needed to work.
There are current limitations to how dynamic lighting could be accomplished from what I've read and seen so far. For one as we don't have proper drawing tools we can call upon with APIs, nor API's to read the current mask. Also as has been noted in other posts, FG is a single-thread application, so overly complicated vector fog of war calculations might hang up all the clients as they are being done over the whole group as the software can only do one thing at a time.
So what I've come down to, similar to what can be seen in the youtube video above. This could be handled by a hex by hex basis (rectangular only for now) using tokens (black, full square sized, of varying opacity) to represent areas of darkness and with some clever math extrapolated from the set grid sizes etc., to remove or replace the tokens depending on if on the GM or player side, and if vision is normal, dim or none etc. Hiding NPC's could be done similarly if outside of view, but that's something I'd worry about later if at all (it's as easy as a mouse click for the GM on the CT after all), focus on the primary functionality first, the 80/20 principle.

My main concern with this at the moment and this approach, is no doubt one of the the technical difficulty limitations that youtube video code creator must have run into as well. Is that you can only do it on a hex by hex basis, that is if you have a map that doesn't have at least one hex between walls, then you're in a tough spot. And as we all know there are plenty of maps such as that out there, castles, houses and ruins come to mind.
So I'm considering if there are other approaches I could take to this atm. Such as for example simulating a vector drawing tool by allowing the rotation and manipulation of a square token to extend out as a line across the map, then figuring out some math to calculating fog of war with that as a "wall" to vision. But then again we get back to the "single thread application" concern.


]]--

-- Global Constants --
local tokenGrid = {}; -- Contains the Lua grid of tokens, holding the token image Id's, later to be stored in a db so it can be kept between sessions
                      -- Load up all added tokens into array with position as key, when token within range, compare calculated position and remove tokens that match the keys calculated from the grid.    
                      -- Token.getToken( containernodename, containerid ) 
local listTokens;   -- list tokens on map              


function onInit()
    --Token.onDrag = updateFOW
    --onClickDown = addFOWBox
    -- of FOW button in toolbar active, then override mouse click to add or remove fow tokens in grids  
    --local ctrlImage, wndImage, bWindowOpened = ImageManager.getImageControl(tokenCT, false);    


end
 

-- called from /campaign/scripts/image.lua : function onClickRelease(button, x, y)
function toggleFOW(x,y,imgctl)
    --Debug.console('Toggle FOW: x', x, 'y', y, 'imgctl', imgctl);
    x, y = imgctl.snapToGrid(x, y);  -- Snaps the specified X and Y coordinate point to the nearest snap point on the imagecontrol, either vertex or center.
    --Debug.console('Snapped x', x, 'y', y);

    --local tokenproto = "tokens/host/5e Combat Enhancer/ping_target.png";	    
    --local tokenproto = "tokens/host/5e Combat Enhancer/FOW_token_100.png";	    
    local tokenproto = "tokens/host/Fog of War Graphics/FOW_token_60.png";	    

	-- check parent for our image control siblings, if we
	-- have an 'image sibling' get that window and place
	-- our marker there else nothing
	local tWndCtls = imgctl.window.getControls(); 
	local wndImgRef = imgctl.window.getDatabaseNode().getPath(); 
	local imgctlPing = nil; 
	for k,v in pairs(tWndCtls) do
		----Debug.console (tostring(k) .. ' ---> ' .. tostring(v.getName())); 
		if v.getName() == 'image' then
			-- we found the image, 
			imgctlPing = v; 
			break; 
		end
    end       

	-- Refresh the references
	local wndImg = Interface.openWindow("imagewindow", wndImgRef); 
	if wndImg then
		tWndCtls = wndImg.getControls(); 
		for k,v in pairs(tWndCtls) do
			--Debug.console('k: ' .. k .. ' v: ' .. tostring(v.getName())); 
			if v.getName() == "image" then
				imgctlPing = v; 
				break; 
			end
		end
    end
        
    --Debug.console('Toggle FOW: tWndCtls', tWndCtls, 'wndImgRef', wndImgRef, 'imgctlPing', imgctlPing);
    listTokens = imgctlPing.getTokens();
    --Debug.chat('listTokens', listTokens);

    if (Input.isShiftPressed()) and imgctlPing then                
        -- Create the token
        local tokenMap = imgctlPing.addToken(tokenproto, x, y);
        --Debug.chat('tokenMap', tokenMap);
        if tokenMap then            
            tokenMap.setVisible(true); 
            --Debug.chat('token container', tokenMap.getContainerNode() )
            --tokenGrid[0][0] = tokenMap.getId();
            --Debug.chat('tokenGrid[0][0]', tokenGrid[0][0])
        end                            
    end    
end

function updateListTokens()
end

-- hides or shows FOW tokens depending on where players token is moved
function updateFOW()    
    --local x, y = Input.getMousePosition();
    --Debug.chat('updateFOW: token moved. x:', x, 'y:', y); 
    
    -- toggle visibility of 2nd token
    for _,token in pairs(listTokens) do 
        --Debug.chat('token Id:', token.getId());
        if token.getId() == 1352 then
            Debug.chat('token 1352');
            token.delete();
        end
    
        --Debug.chat('Token.onDrag token: ', token);
    end   

end



-- look at /scripts/manager_ping.lua for ideas of how to handle mouse click and adding token
function addFOWBox( button, x, y ) 	
    if button == 1 then
        Debug.chat('fow addFOWBox, left mouse button pressed')
        local w = Interface.findWindow("imagewindow", "")	    
        Debug.chat(w)
        
        local tokenproto = "tokens/host/Fog of War Graphics/fow_token_100.png"
        w.addToken(tokenproto, 200, 150)        
        -- imagecontrol.snapToGrid(x,y) --snaps to nearest

        --token.setScale = 1; --100% token scale
        --w.snapToGrid        
    end
end

function fow(nodefield)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	local success = nodeField.getValue(); 
    
    Debug.chat('nodeField', nodefield, 'nodeCT', nodeCT)

    -- add fow token on mouse click in that grid
    -- To Test:
    -- add token on a set x,y grid, snap to grid, 100% gride size




--[[

    tokenFOW = tokenCT.addBitmapWidget(); 
    tokenFOW.setName("success1"); 
    tokenFOW.bringToFront(); 
    tokenFOW.setBitmap("overlay_save_success"); 
    tokenFOW.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
	if tokenCT then
		local wToken, hToken = tokenCT.getSize();
		-- now add the widget
		-- destroy old success widgets if present
		widgetSuccess = tokenCT.findWidget("success1");
		if widgetSuccess then widgetSuccess.destroy() end

		if success == 1 then 
			widgetSuccess = tokenCT.addBitmapWidget(); 
			widgetSuccess.setName("success1"); 
			widgetSuccess.bringToFront(); 
			widgetSuccess.setBitmap("overlay_save_success"); 
			widgetSuccess.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
		elseif success == 2 then
			widgetSuccess = tokenCT.addBitmapWidget(); 
			widgetSuccess.setName("success1"); 
			widgetSuccess.bringToFront(); 
			widgetSuccess.setBitmap("overlay_save_failure"); 
			widgetSuccess.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
        else
            
			-- leave it removed
		end
	end ]]--
end


-- a modified Token.onDrag event, for handling dynamic shadows
--[[
		Functionality
		
		load fog of war file, or tap into default FOW functionality, only limiting actual output on client/player side to a given range as deduced by condition
		containing a defined key effect on CT, such as "FOW: 60/30", to give 60' of vision, the last 30' of which are 
		Custom FOW effect:
			FOW: x/y
			x = x' of total vision
			y = of which the last y' are dim vision, if left blank or at 0, then all vision is treated as total vision

		button to enter shadow mode
		add token to grid with 100% scale (to cover grid); if on player side 100% opacity black .png; if on gm side 20% opacity black .png, so know where fog is.
		check player, check character from CT, look for FOW effect, 
        each square is 5', read custom effect "FOW: 40/20" to determine view range	 	
        
        How to determine what squares to clear:
        1) get grid size
        2) find player token location x,y
        3) divide token x and y location by grid size to find out inside what grid they are
        4) clear tokens on individual player side for their vision
]]--    
function fogOfWar(token, mouseButton, x, y, dragdata)
    Debug.chat("token ", token)
    --local image = UpdatedImageWindow.image
    Debug.chat("controls ", image)
    local gridType = image.getGridType() -- only work with square hexes for simplicy to begin with
    local gridSize = image.getGridSize()
    local gridOffset = image.getGridOffset()
    local maskTool = image.getMaskTool()
    local maskLayer = image.hasMask()

    image.setMaskEnabled(true)
    image.setDrawingSize(500, 500, 50, 50)
    -- make selection
    -- mask or unmask
    image.setMaskTool(unmaskelection) --Valid values are "maskselection" and "unmaskelection

    --Debug.chat('image ', image, ' gridType ', gridType)
end
