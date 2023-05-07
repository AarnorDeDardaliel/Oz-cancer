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
         Ans
      end
   end

   proc {PressHelper} % Procédure exécutée par chaque thread après l'initialisation (Useless pour le moment je pense. Pour les bonus ?)
      Dummy = 0
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Read File and send words on BuffTail - 1 thread for each file exec
   % WordHead and WordTail are used to assemble caracs into words, as we read the file
   % Valid is 1 if there is at least 1 letter in the word
   proc {Read1File File BuffTail Valid WordHead WordTail}
      local NewBuffTail NewValid NewWordHead NewWordTail in
         local
            proc {Manage Carac}
               local
                  proc {Skip}
                     NewBuffTail = BuffTail
                     NewValid = Valid
                     NewWordHead = WordHead
                     NewWordTail = WordTail
                  end
                  proc {SendWord X}
                     if Valid == 1 then
                        WordTail = nil
                        BuffTail = WordHead|NewBuffTail
                        NewWordHead = NewWordTail
                        NewValid = 0
                     else {Skip} end
                  end
                  proc {SendEndWord X}
                     if Valid == 1 then
                        WordTail = nil
                        BuffTail = WordHead|"\n"|NewBuffTail
                        NewWordHead = NewWordTail
                        NewValid = 0
                     else {Skip} end
                  end
               in
                  % If Carac == "'" ou "-", skip (transmettre les variables à la récursion suivante)
                  % If Carac == " ", add nil à WordHead et l'envoie sur le Buffer. NewWordHead = NewBuffTail = stream vide.
                  % If Carac == ".", "!", "\n" ou nil, même chose mais envoie aussi le mot "\n" sur le Buffer ("\n\n\n" pour nil) => Les retours à la ligne sont des "\r\n", mais étrangement on peut ignorer les "\r"
                  % Sinon, NewWordHead = WordHead, BuffTail = Carac|NewBuffTail
                  case Carac of "'" then {Skip}
                  [] "-" then {Skip}

                  [] " " then {SendWord WordHead}
                  [] "," then {SendWord WordHead}

                  [] "!" then {SendEndWord WordHead}
                  [] "." then {SendEndWord WordHead}
                  [] "\n" then {SendEndWord WordHead}
                  [] nil then {SendEndWord WordHead}
                  
                  else % Ajouter la lettre au mot
                     NewWordHead = WordHead
                     WordTail = Carac.1|NewWordTail
                     NewValid = 1
                  end
               end
            end
         in
            {File read(list:{Manage} size:1)}
            {Read1File File NewBuffTail NewValid NewWordHead NewWordTail}
         end
      end
   end
   % Read File(s) and send on LocBuff - thread number imposed
   proc {ReadXFile N Total Folder Tail}
      Dummy = 0
   end




   % 
   % Count = 0
   % Triples = []
   % Sent : []
   % 
   % Count = 1
   % Triples = [["coucou,"]]
   % Sent : []
   % 
   % Count = 2
   % Triples = [["coucou," "Je"] ["Je"]]
   % Sent : []
   % 
   % Count = 3
   % Triples = [["Je" "M'appelle"] ["M'appelle"]]
   % Sent : ["coucou," "Je" "M'appelle"]
   % 
   % 
   % Count = 3
   % Triples = [["M'appelle" "Bryce,"] ["Bryce,"]]
   % Sent : ["coucou," "Je" "M'appelle"] ["Je" "M'appelle" "Bryce,"]
   % 
   % Count = 3
   % Triples = [["coucou," "Je" "M'appelle"] ["Je" "M'appelle"] ["M'appelle"]]
   % Sent : ["coucou," "Je" "M'appelle"]


   % Parse LocBuff : Faire des listes de N mots en les envoyer sur le Port
   proc {ParseBuffer N Buffer Port TheWord Tail}
      local NewWord NewTail in
         local
            proc {Parse Word}
               % TODO : Faire des triplettes avec le stream de words
               {Browse Word}
               Dummy = 0
            end
         in
            case Buffer of
            W|S2 then {Parse W} {ParseBuffer N S2 Port NewWord NewTail}
            [] nil then skip end
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
   %%% Les threads de parsing envoient leur resultat au port Port
   proc {LaunchThreads Port NbThreads}
      local 
         FoldName = {Append TweetsFolder "/"}
         % Execution si on veut 2 threads par file (1 pour lire, 1 pour parse)
         proc {FullLaunchThreads Folder}
            case Folder of nil then skip
            [] H|T then
               thread
                  local LocBuf Tail File Name in
                     % Thread pour parser les infos (N-gramme)
                     thread local Empty in {ParseBuffer 3 LocBuf Port Empty Empty} end {PressHelper} end
                     
                     % Lit les fichiers !! (sous-fonction récursive pour Tail)
                     Name = {Append FoldName H}
                     File = {New Open.file init(name:{String.toAtom Name} flags:[read])}
                     LocBuf = Tail
                     local Empty in {Read1File File Tail 0 Empty Empty} end
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
            Mid = NbThreads div 2
            SourceFolder = {OS.getDir TweetsFolder}
            case Mid of NFiles then {FullLaunchThreads SourceFolder} else {DefLaunchThreads SourceFolder} end
         end
      end
   end

   % Enregistre les N-gramme dans la database. Compte également le nombre de Threads qui ont terminé pour savoir quand s'arrêter
   % ATTENTION, valeur initiale de NilCount = 1 !!
   proc {SaveFromStream TheStream TreeDatabase NilCount NbThreads}
      case TheStream of H|T then
         case H of nil then
            {Browse 0}
            case NilCount of NbThreads then skip else {SaveFromStream T TreeDatabase NilCount+1 NbThreads} end
         else
            % TODO : Enregistrer H dans TreeDatabase !
            {InsertFirst H TreeDatabase}

            {SaveFromStream T TreeDatabase NilCount NbThreads}
         end
      end
   end

   proc {InsertFirst H Tree}
      case H|T of
	 nil then nil
      [] if T==nil then nil
	 end
      end
      
      case Tree of leaf then %there is no database for the moment
	 tree(key:H.1 value:H.2.1 leaf leaf)
	 {InsertSec H.2 leaf} %for the moment, the second tree doens't exist
      [] tree(key:Y value:V T1 T2) andthen H.1 == Y then %means we found first word, we must insert in the second tree which is V
	 {InsertSec H.2 V}
      [] tree(key:Y value:V T1 T2) andthen H.1 < Y then
	 tree(key: Y value:V  {InsertFirst H.1 T} T2)
      [] tree(key:Y value:V T1 T2) andthen H.1 > Y then
	 tree(key: Y value:V T1 {InsertFirst H.1 T})
      end
   end

   proc  {InsertSec H Tree}
      case H|T of
	 nil then nil
      [] if T==nil then nil
	 end
      end
      case Tree of leaf then %the 2nd tree doesn't exist
	 tree(key:H.1 value:H.2 leaf leaf) %we've initialised the 3rd to be word|nil and we will build rest of list off of this
      [] tree(key:Y value:V T1 T2) andthen H.1 == Y then %we add the 3word to the list of words
	 tree(key: Y value H.2.1|V T1 T2)
      [] tree(key:Y value:V T1 T2) andthen H.1 < Y then
	 tree(key: Y value:V  {InsertSec H.1 T} T2)
      [] tree(key:Y value:V T1 T2) andthen H.1 > Y then
	 tree(key: Y value:V T1 {InsertSec H.1 T})
      end
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
         NbThreads = NFiles * 2
         SeparatedWordsPort = {NewPort SeparatedWordsStream}
         {LaunchThreads SeparatedWordsPort NbThreads}
         {SaveFromStream SeparatedWordsStream TreeDatabase 1 NbThreads}
      
         {InputText set(1:"")}
      end
   end
   % Appelle la procedure principale
   {Main}
end