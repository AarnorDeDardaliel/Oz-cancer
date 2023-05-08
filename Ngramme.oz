
   % ====== Schéma simplifié : ============
   %
   %
   %         WordHead   
   %             |     
   % WorkTree  [[X Y T1] [Y T2] _]
   % WorkTails  [T1 T2 _] 
   %             |   
   %          WordTail 
   %             
   %  
   %




   %           => EXEMPLE POUR N = 2 <=
   %
   % ======================================================
   % ============ COUNT = 0, STEP = 0, WORD = X ===========
   %
   %         WordHead  
   %             |   
   % WorkTree  [T1]
   % WorkTails [T1] 
   %             | 
   %          WordTail
   %            
   %      
   %
   %                       NewTreeTail
   %         WordHead           |
   %             |              |
   % WorkTree  [[X|NewWordTail] _]
   % WorkTails [T1] 
   %             |   
   %          WordTail
   %               
   %          
   %
   %                        NewTreeTail
   %         WordHead            |
   %             |               |
   % WorkTree  [[X|NewWordTail] T2]
   % WorkTails [NewWordTail T2] 
   %             | 
   %          WordTail
   %    
   %
   %
   %  ======================================================
   %  ============ COUNT = 1, STEP = 0, WORD = Y ===========
   %                    
   %         WordHead    
   %             |         
   % WorkTree  [[X|T1] T2]
   % WorkTails [T1 T2]
   %             |           
   %          WordTail   
   %
   %                  
   %
   %         WordHead     
   %             |          
   % WorkTree  [[X|Y|T3] T2]
   % WorkTails [Y|T3 T2] 
   %            |   
   %         WordTail    
   %                     
   % NewWorkTails = T3|NewTailsTail 
   %
   %
   %                  
   % ===============> STEP = 1 <===============
   %
   %                   WordHead     
   %                      |          
   % WorkTree  [[X|Y|T3] T2]
   % WorkTails [Y|T3 T2] 
   %                  |   
   %               WordTail
   %                     
   % NewWorkTails = T3|NewTailsTail 
   %
   %
   %
   %                         WordHead     
   %                            |          
   % WorkTree  [[X|Y|T3] [Y|NewWordTail] NewTreeTail]
   % WorkTails [Y|T3 [Y|NewWordTail] NewTreeTail] 
   %                       |   
   %                   WordTail    
   %                     
   % NewWorkTails = T3|NewTailsTail
   %
   %
   %
   %                     WordHead     
   %                        |          
   % WorkTree  [[X|Y|T3] [Y|T4] NewTreeTail]
   % WorkTails [Y|T3 [Y|T4] NewTreeTail] 
   %                   |   
   %                WordTail    
   %                     
   % NewWorkTails = T3|T4|NewTreeTail 
   % 
   %
   %
   %  ======================================================
   %  ============ COUNT = 2, STEP = 0, WORD = Z ===========
   %
   %          WordHead     
   %             |          
   % WorkTree  [[X|Y|T3] [Y|T4] T5]
   % WorkTails [T3 T4 T5] 
   %            | 
   %         WordTail 
   %  
   %
   %          
   %          WordHead     
   %             |          
   % WorkTree  [[X|Y|Z] [Y|T4] T5]
   % WorkTails [[Z] T4 T5]                  => {Send Port [X|Y|Z]}
   %             | 
   %         WordTail 
   %  
   %
   %          
   %                  NewWorkTree
   %          WordHead   |  
   %             |       |   
   % WorkTree  [[X|Y|Z] [Y|T4] T5]
   % WorkTails [[Z] T4 T5] 
   %             | 
   %         WordTail 
   % 
   %
   %
   %  ===============> STEP = 1 <===============  
   %          
   %                 NewWorkTree
   %                  WordHead  
   %                     |   
   % WorkTree  [[X|Y|Z] [Y|T4] T5]
   % WorkTails [[Z] T4 T5] 
   %                | 
   %             WordTail 
   %
   %
   %          
   %                 NewWorkTree
   %                  WordHead  
   %                     |   
   % WorkTree  [[X|Y|Z] [Y|Z|NewWordTail] T5]
   % WorkTails [[Z] [Z|NewWordTail] T5] 
   %                 | 
   %              WordTail 
   %
   % NewWorkTails = NewWordTail|NewTailsTail
   % 
   %
   %
   %  ===============> STEP = 2 <=============== 
   %          
   %                 NewWorkTree
   %                     |             WordHead  
   %                     |   			   |
   % WorkTree  [[X|Y|Z] [Y|Z|T6] [Z|NewWordTail] NewTreeTail]
   % WorkTails [[Z] [Z|T6] [Z|NewWordTail] NewTreeTail] 
   %                                 | 
   %                             WordTail 
   %
   % NewWorkTails = T6|NewTailsTail
   %
   %
   %          
   %                 NewWorkTree
   %                     |             WordHead  
   %                     |   			   |
   % WorkTree  [[X|Y|Z] [Y|Z|T6] [X|NewWordTail] NewTreeTail]
   % WorkTails [[Z] [Z|T6] [X|NewWordTail] NewTreeTail] 
   %                                 | 
   %                             WordTail 
   %
   % NewWorkTails = T6|NewWordTail|NewTreeTail
   % 
   %
   %
   % ======================================================
   % ============ COUNT = 3, STEP = 0, WORD = A =========== 
   %
   %          WordHead  
   %             |
   % WorkTree  [[Y|Z|T6] [X|T7] T8]
   % WorkTails [T6 T7 T8] 
   %             | 
   %          WordTail 
   %
   %
   % 
   %    (=> Même situation que COUNT=2 : WIN !! <=)



   %  . . .

