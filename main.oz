functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Application
   Open
   OS
   Property
   Browser
define
   Dummy % Variable for dev
   TreeDatabase % Variable Globale
   NFiles % Variable globale
   TweetsFolder % Variable globale
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Pour ouvrir les fichiers
   class TextFile
      from Open.file Open.text
   end

   %{BrowserObject.option(representation strings:true)}
   proc {Browse Buf}
      {Browser.browse Buf}
   end
   
   %%% /!\ Fonction testee /!\
   %%% @pre : les threads sont "ready"
   %%% @post: Fonction appellee lorsqu on appuie sur le bouton de prediction
   %%%        Affiche la prediction la plus probable du prochain mot selon les deux derniers mots entres
   %%% @return: Retourne une liste contenant la liste du/des mot(s) le(s) plus probable(s) accompagnee de
   %%%          la probabilite/frequence la plus elevee.
   %%%          La valeur de retour doit prendre la forme:
   %%%                  <return_val> := <most_probable_words> '|' <probability/frequence> '|' nil
   %%%                  <most_probable_words> := <atom> '|' <most_probable_words>
   %%%                                           | nil
   %%%                  <probability/frequence> := <int> | <float>
   fun {Press}
      local Ans Val Freq in
         % TODO : Chercher la liste dans TreeDatabase
         % Etablir la réponse
         Val = nil % Liste des most probable words
         Freq = 0
	 Ans = Val | Freq | nil
	 %Listofwords = {FindFirst Words TreeDatabase} %Words are the two words that the users has writte 
         Ans
      end
   end

   proc {PressHelper} % Procédure exécutée par chaque thread après l'initialisation (Useless pour le moment je pense. Pour les bonus ?)
      Dummy = 0
   end

   %fun {FindFirst Words Tree}
    %  case Tree
     % of leaf then nil
      %[] tree(key:Y value:V T1 T2) andthen Words.1 == Y then
%	 {FindSec Words.2 V}
 %     [] tree(key:Y value:V T1 T2) andthen Words.1 < Y then
%	 {FindFirst Words T1}
 %     [] tree(key:Y value:V T1 T2) andthen Words.1 > Y then
%	 {FindFirst Words T2}
 %  end
%end
%fun {FindSec Words Tree}
 %  case Tree
  % of leaf then nil
   %[] tree(key:Y value:V T1 T2) andthen Words.1 == Y then
    %  V
   %[] tree(key:Y value:V T1 T2) andthen Words.1 < Y then
    %  {FindSec Words T1}
   %[] tree(key:Y value:V T1 T2) andthen Words.1 > Y then
    %  {FindSec Words T2}
   %end
%end      
      
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Read File and send words on BuffTail - 1 thread for each file exec
   % WordHead and WordTail are used to assemble caracs into words, as we read the file
   % Valid is 1 if there is at least 1 letter in the word
   proc {Read1File File BuffTail}
      local NewBuffTail TheChar in
         local
            proc {Manage Carac} 
               TheChar = Carac
               BuffTail = Carac|NewBuffTail 
            end
         in
            {File read(list:{Manage} size:1)}
            case TheChar of nil then skip
            else {Read1File File NewBuffTail}
            end
         end
      end
   end
   % Read File(s) and send on LocBuff - thread number imposed
   proc {ReadXFile N Total Folder Tail}
      Dummy = 0
   end

   % Parse CaracBuff : Rassembler les caractères récupérés sur CaracBuff en mots et les envoyer sur WordBuff
   proc {ParseCaracs CaracBuff Head Tail WordBuff}
      local NewHead NewTail NewWordBuff in
         local
            proc {Parse Carac}
               local
                  proc {Skip}
                     NewWordBuff = WordBuff
                     NewHead = Head
                     NewTail = Tail
                  end
                  proc {SendWord X}
                     Tail = nil
                     WordBuff = X|NewWordBuff
                     NewHead = NewTail
                  end
                  proc {SendEndWord X}
                     Tail = nil
                     WordBuff = X|"\n"|NewWordBuff
                     NewHead = NewTail
                  end
               in
                  % Signale une fin de phrase
                  case Carac of nil then {SendEndWord Head}
                  [] "!" then {SendEndWord Head}
                  [] "." then {SendEndWord Head}
                  [] "\n" then {SendEndWord Head}
                  
                  % Signale une fin de mot
                  [] " " then {SendWord Head}
                  [] "," then {SendWord Head}
                  
                  % A ignorer
                  [] "'" then {Skip}
                  [] "-" then {Skip}
                  
                  else % Ajouter la lettre au mot
                     NewHead = Head
                     Tail = Carac.1|NewTail
                     NewWordBuff = WordBuff
                  end
               end
            end
         in
            case CaracBuff
            of W|S2 then 
               case W of nil then {Parse W} NewWordBuff = nil
               else {Parse W} {ParseCaracs S2 NewHead NewTail NewWordBuff}
               end
            [] nil then skip end
         end
      end
   end

   % Parse WordBuff : Faire des listes de N mots en les envoyer sur le Port
   % Inputs :
   %     - N : Le N de "N-gramme"
   %     - WordBuff : Le buffer de mots à lire
   %     - Port : Le Port sur lequel envoyer les listes
   %     - 
   %     - 
   %     - 
   % Procédure pour chaque mot : 
   %     - L'ajoute à la première étape du WorkTree
   %     - Si Count est > N, l'envoie prends le suivant comme future tête
   %     - L'ajoute aux étapes suivantes
   %     - Crée l'étape suivante avec le mot
   %
   %     => POUR ETAPES VISUELLES, VOIR Ngramme.oz !!
   %
   proc {ParseWords N WordBuff Port WorkTree WorkTails Count}
      local NewWorkTree NewWorkTails NewTailsTail in
         local
            proc {Manage WordHead WordTail X Step}
               % {Browse Count|Step|nil}
               % {Browse WordHead}

               local NewWordTail NewTreeTail in
                  if Step == Count then % Ajouter l'étape suivante, puis si c'est le tout premier set NewWorkTree et NewWorkTree, sinon juste NewTailsTail
                     WordHead = (X|NewWordTail)|NewTreeTail
                     if Step == 0 then
                        WordTail = NewWordTail|NewTreeTail
                        NewWorkTree = WorkTree
                        NewWorkTails = WorkTails
                     else % Step == Count > 0, NewTailsTail a déjà été link à NewWorkTails !
                        NewTailsTail = NewWordTail|NewTreeTail
                     end

                  elseif Step == 0 then
                     if Count < N then
                        % Si Count est < N (équilibre pas encore atteint), ajouter X mais garder le même NewWorkTree (et set NewWorkTails = NewWordTail|NewTailsTail)
                        WordTail.1 = X|NewWordTail
                        NewWorkTails = NewWordTail|NewTailsTail
                        
                        NewWorkTree = WorkTree
                        {Manage WordHead.2 WordTail.2 X Step+1}  
                     else
                        % Sinon ajouter X aussi et envoyer sur le Port, puis prends le suivant comme NewWorkTree
                        % Redéfinir NewWorkTails au fur et à mesure !!
                        WordTail.1 = X|nil
                        {Send Port WordHead.1}
                        NewWorkTree = WorkTree.2
                        {Manage WordHead.2 WorkTails.2 X Step+1}
                     end
                     
                  elseif Step == N then % Ajouter l'étape suivante et c'est fini ! (Pareil que Step == Count > 0, mais chiant et inutile de bloquer Count à N)
                     WordHead = (X|NewWordTail)|NewTreeTail
                     NewTailsTail = NewWordTail|NewTreeTail

                  else
                     % Sinon, ajouter X à l'étape suivante "normalement"
                     WordTail.1 = X|NewWordTail
                     NewWorkTails = NewWordTail|NewTailsTail

                     {Manage WordHead.2 WordTail.2 X Step+1}
                  end 
               end
            end
         in
            case WordBuff
            of H|T then
               case H of "\n" then % Fin de phrase
                  {ParseWords N T Port NewWorkTree NewWorkTails 0}
               else
                  {Manage WorkTree WorkTails H 0}
                  {ParseWords N T Port NewWorkTree NewWorkTails Count+1}
               end
            [] nil then {Send Port nil} % Fin d'exécution !
            end
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
   %%% Les threads de parsing envoient leur resultat au port Port
   proc {LaunchThreads Port NbThreads}
      local
         FoldName = {Append TweetsFolder "/"}
         % Execution si on veut 3 threads par file (1 pour lire, 2 pour parse)
         proc {FullLaunchThreads Folder}
            case Folder of nil then skip
            [] H|T then
               thread
                  local File Name CaracBuff WordBuff in

                     % Thread pour parser les infos (N-gramme)
                     thread local LocBuff in {ParseCaracs CaracBuff LocBuff LocBuff WordBuff} end {PressHelper} end
                     thread local LocBuff2 LocTails2 in {ParseWords 2 WordBuff Port LocBuff2 LocTails2 0} end {PressHelper} end
                     
                     % Lit les fichiers !! (sous-fonction récursive pour CaracTail)
                     Name = {Append FoldName H}
                     File = {New Open.file init(name:{String.toAtom Name} flags:[read])}
                     local Empty in {Read1File File CaracBuff} end
                  end
                  {PressHelper}
               end
               {FullLaunchThreads T}
            end
         end
         % Execution pour un nombre de threads imposé
         proc {DefLaunchThreads Folder}
            {Browse 0}
         end
      in
         % Lancement de la procédure
         local Mid SourceFolder in
            Mid = NbThreads div 3
            SourceFolder = {OS.getDir TweetsFolder}
            case Mid of NFiles then {FullLaunchThreads SourceFolder} else {DefLaunchThreads SourceFolder} end
         end
      end
   end

   % Enregistre les N-gramme dans la database. Compte également le nombre de Threads qui ont terminé pour savoir quand s'arrêter
   % ATTENTION, valeur initiale de NilCount = 1 !!
   proc {SaveFromStream TheStream NilCount NbThreads LocDatabase}
      case TheStream of H|T then
         case H of nil then
            {Browse 0}
            case NilCount of NbThreads then 
               TreeDatabase = LocDatabase 
               {Browse TreeDatabase}
            else {SaveFromStream T NilCount+1 NbThreads LocDatabase} end
         else
            % TODO : Enregistrer H dans TreeDatabase ! (Pour l'instant je fais avec une liste)
            {SaveFromStream T NilCount NbThreads H|LocDatabase}
         end
      end
   end

   proc {InsertFirst H}
      %case H|T of
	   %nil then nil
      %[] T==nil then nil
	   %end
      %
      %case Tree of leaf then %there is no database for the moment
	      %tree(key:H.1 value:H.2.1 leaf leaf)
	      %{InsertSec H.2 leaf} %for the moment, the second tree doens't exist
      %[] tree(key:Y value:V T1 T2) andthen H.1 == Y then %means we found first word, we must insert in the second tree which is V
	      %{InsertSec H.2 V}
      %[] tree(key:Y value:V T1 T2) andthen H.1 < Y then
	      %tree(key: Y value:V  {InsertFirst H T} T2)
      %[] tree(key:Y value:V T1 T2) andthen H.1 > Y then
	      %tree(key: Y value:V T1 {InsertFirst H T})
      %end
      
      Dummy = 0
   end

   proc  {InsertSec H}
      %case H|T 
      %of nil then nil
      %[] T==nil then nil
      %end

      %case Tree of leaf then %the 2nd tree doesn't exist
	      %tree(key:H.1 value:H.2 leaf leaf) %we've initialised the 3rd to be word|nil and we will build rest of list off of this
      %[] tree(key:Y value:V T1 T2) andthen H.1 == Y then %we add the 3word to the list of words
	      %tree(key: Y value H.2.1|V T1 T2)
      %[] tree(key:Y value:V T1 T2) andthen H.1 < Y then
	      %tree(key: Y value:V  {InsertSec H T} T2)
      %[] tree(key:Y value:V T1 T2) andthen H.1 > Y then
	      %tree(key: Y value:V T1 {InsertSec H T})
      %end

      Dummy = 0
   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Fetch Tweets Folder from CLI Arguments
   %%% See the Makefile for an example of how it is called
   fun {GetSentenceFolder}
      Args = {Application.getArgs record('folder'(single type:string optional:false))}
   in
      Args.'folder'
   end
    
   %%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
   proc {Main}
      local NbThreads SourceFolder InputText OutputText Description Window SeparatedWordsStream SeparatedWordsPort in
         {Property.put print foo(width:1000 depth:1000)}  % for stdout siz
      
         % Creation de l'interface graphique
         Description=td(
            title: "Text predictor"
            lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:Press))
            text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
            action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
         )
      
         % Creation de la fenetre
         Window={QTk.build Description}
         {Window show}
      
         {InputText tk(insert 'end' "Loading... Please wait.")}
         {InputText bind(event:"<Control-s>" action:Press)} % You can also bind events
      
         % Compter le nombre de fichiers
         TweetsFolder = {GetSentenceFolder}
         SourceFolder = {OS.getDir TweetsFolder}
         local
            fun {CountAllFiles LocFolder Acc}
               case LocFolder of nil then Acc
               [] H|T then  {CountAllFiles T Acc+1}
               end
            end
         in
            NFiles = {CountAllFiles SourceFolder 0}
         end

         % On lance les threads de lecture et de parsing, puis de création de la Database
         NbThreads = NFiles * 3
         SeparatedWordsPort = {NewPort SeparatedWordsStream}
         {LaunchThreads SeparatedWordsPort NbThreads}
         {SaveFromStream SeparatedWordsStream 1 NbThreads nil}
      
         {InputText set(1:"")}
      end
   end
   % Appelle la procedure principale
   {Main}
end