function preReadCentrelines( input, output )
% MATLAB refuses to read all airway (and specially vessel) centrelines files in 1 go without using at leas 24GB of memory.
% So you can run this to convert the .m files into .mat files that can be read without destroying the memory

    run(input)
    save(output, 'airway');

end
