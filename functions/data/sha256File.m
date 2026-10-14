function hash = sha256File(fileName)
%SHA256FILE Compute the lowercase SHA-256 digest of a local file.
%
%   HASH = SHA256FILE(FILENAME) reads FILENAME as bytes and returns a
%   64-character lowercase hexadecimal digest.

arguments
    fileName (1,1) string
end

if ~isfile(fileName)
    error('STA4028Z:MissingFile', 'File does not exist: %s', fileName);
end

fileId = fopen(fileName, 'rb');
if fileId < 0
    error('STA4028Z:UnreadableFile', 'Unable to open file: %s', fileName);
end
cleanup = onCleanup(@() fclose(fileId));
bytes = fread(fileId, Inf, '*uint8');

digest = java.security.MessageDigest.getInstance('SHA-256');
% Java byte arrays are signed int8; typecast preserves the underlying bits.
digest.update(typecast(bytes, 'int8'));
hashBytes = typecast(digest.digest(), 'uint8');
hash = lower(string(reshape(dec2hex(hashBytes, 2).', 1, [])));
end
