function [vp, instruct, responseHand, rkeys, self] = get_experimentInfo()
  vp = input('\nParticipant (three characters, e.g. S01)?\n', 's');
    if length(vp)~=3 
       error ('Use three characters for the name, e. g. ''S01'''); end

   response_mapping = str2num(input('\nResponse mapping?\n1: left hand, \n2: right hand\n', 's'));    
      if ~ismember(response_mapping, [1, 2])
        error('\nUse only numbers 1 or 2 for the response mapping.'); end
   
    switch response_mapping
    case  1
        instruct = 'Antworten Sie mit der linken Hand.\n\n';
        responseHand = 'left';
    case  2
        instruct = 'Antworten Sie mit der rechten Hand.\n\n';
        responseHand = 'right';
    end
rkeys = {'y', 'x'};
instr2 = '\n(korrekt)    Y - X    (nicht korrekt)\n\n\nDrücken Sie eine der Antworttasten, um den Durchgang zu starten.\n';
instruct = [instruct, instr2]; 

haendigkeit_nr = str2num(input('\nHändigkeit?\n1: Rechtshänder, \n2: Linkshänder\n', 's'));    
      if ~ismember(haendigkeit_nr, [1, 2])
        error('\nUse only numbers 1 or 2 for Händigkeit.'); end
if haendigkeit_nr == 1
    haendigkeit = 'Sie sind Rechtshänder.';
elseif haendigkeit_nr == 2
    haendigkeit = 'Sie sind Linkshänder.';
end

alter_nr = input('\nAlter?\n', 's');
alter = ['Sie sind ', alter_nr, ' Jahre alt.'];

groesse_nr = input('\nKörpergröße in cm?\n', 's');
groesse = ['Sie sind ', groesse_nr ' cm groß.'];

auge       = input('\nAugenfarbe?\n', 's');
augenfarbe = ['Sie haben ', auge 'e Augen.'];
self.text  = {haendigkeit, alter, groesse, augenfarbe};
self.con = {'handeness', 'age', 'body_height', 'eye_color'};

end

    

