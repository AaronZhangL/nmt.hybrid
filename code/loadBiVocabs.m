function [srcVocab, tgtVocab, params] = loadBiVocabs(params)
  srcVocab = {};
  if params.isGradCheck
    if params.posModel>0
      params.posWin = 2;
      tgtVocab = {'a', 'b', '<p_-2>', '<p_-1>', '<p_0>', '<p_1>', '<p_2>', '<p_n>'};
    else
      if params.numClasses>0
        tgtVocab = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'};
      else
        tgtVocab = {'a', 'b'};
      end
    end
    
    if params.isBi
      srcVocab = {'x', 'y'};
    end
  else
    [tgtVocab] = loadVocab(params.tgtVocabFile);    
    if params.isBi
      [srcVocab] = loadVocab(params.srcVocabFile);
    end
  end
  
  % add special symbols to vocabs
  if params.isBi
    fprintf(2, '## Bilingual setting\n');
    
    %% positional vocab
    if params.posModel>0
      params.posVocabSize = 2*params.posWin + 3; % for W_softPos, -posWin, ..., 0, posWin, p_n, p_eos
      params.startPosId = length(tgtVocab) - 2*params.posWin - 1; % marks -posWin
      params.zeroPosId = params.startPosId + params.posWin;
      
      % assert: -posWin, ..., 0, posWin, p_n are those last words in the tgtVocab
      assert(params.startPosId == (length(srcVocab)+1), 'startPosId %d != srcVocab %d + 1\n', params.startPosId, length(srcVocab));
      for ii=1:(2*params.posWin +1)
        relPos = ii-params.posWin-1;
        assert(strcmp(tgtVocab{params.startPosId + ii - 1}, ['<p_', num2str(relPos), '>'])==1);
      end
      % p_n
      params.nullPosId = length(tgtVocab);
      assert(strcmp(tgtVocab{params.nullPosId}, '<p_n>')==1);
      % p_eos
      tgtVocab{end+1} = '<p_eos>';
      params.eosPosId = length(tgtVocab);
      
      fprintf(2, '# Positional model: zeroPosId %s=%d, nullPosId %s=%d, eosPosId %s=%d\n', tgtVocab{params.zeroPosId}, params.zeroPosId, tgtVocab{params.nullPosId}, params.nullPosId, tgtVocab{params.eosPosId}, params.eosPosId);
      fprintf(params.logId, '# Positional model: zeroPosId %s=%d, nullPosId %s=%d, eosPosId %s=%d\n', tgtVocab{params.zeroPosId}, params.zeroPosId, tgtVocab{params.nullPosId}, params.nullPosId, tgtVocab{params.eosPosId}, params.eosPosId);
    end
    
    %% append src vocab
    srcVocab{end+1} = '<s_eos>';
    params.srcEos = length(srcVocab);
    srcVocab{end+1} = '<s_sos>';
    params.srcSos = length(srcVocab);
    % here we have src eos, so we don't need tgt sos.
    params.srcVocabSize = length(srcVocab);
  else
    fprintf(2, '## Monolingual setting\n');
    srcVocab = {};
    tgtVocab{end+1} = '<t_sos>';
    params.tgtSos = length(tgtVocab);
  end
  if params.numClasses>0 % make sure vocab size is divisible by numClasses
    remain = params.numClasses - mod(length(tgtVocab)+1, params.numClasses); % imagine after adding <t_eos>, how many words do we still need?
    for ii=1:remain
      tgtVocab{end+1} = ['<dummy', num2str(ii), '>'];
    end
    fprintf('# Using class-based softmax, numClasses=%d, adding %d dummy words, tgt vocab size now = %d\n', params.numClasses, remain, length(tgtVocab)+1);
  end
  tgtVocab{end+1} = '<t_eos>';
  params.tgtEos = length(tgtVocab);
  params.tgtVocabSize = length(tgtVocab);
  params.vocab = [tgtVocab srcVocab];
  
  if params.isBi
    params.srcSosVocabId = params.srcSos + params.tgtVocabSize;
    params.srcEosVocabId = params.srcEos + params.tgtVocabSize;
  end
end
