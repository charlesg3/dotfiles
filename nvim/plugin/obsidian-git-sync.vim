" Obsidian Git Sync Plugin
" Automated git workflow for obsidian-notes with cursor-agent integration

if !exists('*ObsidianGitSync')
    function! ObsidianGitSync()
        " Save current buffer first
        silent! write
        
        " Check if we're in obsidian-notes directory
        let current_dir = expand('%:p:h')
        if current_dir !~ 'obsidian-notes'
            echo "Not in obsidian-notes directory"
            return
        endif
        
        echo "Starting git sync..."
        
        " Change to the obsidian-notes directory
        let obsidian_dir = expand('~/src/obsidian-notes')
        execute 'cd ' . obsidian_dir
        
        " Check if there are changes
        let status = system('git status --porcelain')
        if empty(status)
            echo "No changes to commit"
            " Still do pull
            echo "Pulling changes..."
            let pull_result = system('git pull 2>&1')
            if v:shell_error == 0
                echo "Successfully pulled changes"
                execute 'edit!'
            else
                echo "Pull failed: " . pull_result
            endif
            return
        endif
        
        " Add all files
        echo "Adding files to git..."
        call system('git add -A')
        
        " Get diff for cursor-agent
        let diff = system('git diff --cached')
        
        " Use cursor-agent to generate commit message
        echo "Generating commit message with cursor-agent..."
        let temp_file = tempname()
        call writefile(split(diff, "\n"), temp_file)
        let prompt = 'Based on these git changes, generate ONLY a git commit message in this exact format:\n\nLine 1: Brief summary (50 chars max)\n\nLine 3+: Bullet points with detailed changes\n\nReturn ONLY the commit message text, no labels, no alternatives, no extra text.\n\nChanges:\n' . diff
        let commit_msg = system('cursor-agent -p ' . shellescape(prompt))
        call delete(temp_file)
        
        if v:shell_error != 0
            echo "Failed to generate commit message, using default"
            let commit_msg = "Update obsidian notes"
        endif
        
        " Clean up the commit message (remove quotes, extra whitespace, labels)
        let commit_msg = substitute(commit_msg, '^\s*\|\s*$', '', 'g')
        let commit_msg = substitute(commit_msg, '^["'']', '', '')
        let commit_msg = substitute(commit_msg, '["'']$', '', '')
        " Remove common prefixes from AI output
        let commit_msg = substitute(commit_msg, '^\(Suggested commit message:\|Commit message:\|Here''s the commit message:\)\s*', '', 'i')
        " Remove "Alternative:" and everything after it
        let commit_msg = substitute(commit_msg, '\n\s*\(Alternative:\|Alternatively:\).*', '', 'i')
        
        " Add timestamp to commit message
        let timestamp = strftime('%Y-%m-%d %H:%M:%S')
        let commit_msg = commit_msg . ' ' . timestamp
        
        " Commit changes
        echo "Committing: " . commit_msg
        let commit_result = system('git commit -m "' . escape(commit_msg, '"') . '" 2>&1')
        if v:shell_error != 0
            echo "Commit failed: " . commit_result
            return
        endif
        
        " Pull changes
        echo "Pulling changes..."
        let pull_result = system('git pull 2>&1')
        
        " Check for merge conflicts
        if pull_result =~ 'CONFLICT'
            echo "Merge conflicts detected. Using cursor-agent to resolve..."
            
            " Get list of conflicted files
            let conflicts = system('git diff --name-only --diff-filter=U')
            let conflict_files = split(conflicts, "\n")
            
            for file in conflict_files
                let content = readfile(file)
                let content_str = join(content, "\n")
                
                " Use cursor-agent to resolve conflicts
                let resolved = system('cursor-agent -p "Resolve these git merge conflicts and return only the resolved file content:\n\n' . content_str . '"')
                
                if v:shell_error == 0
                    call writefile(split(resolved, "\n"), file)
                    call system('git add ' . shellescape(file))
                endif
            endfor
            
            " Complete the merge
            call system('git commit --no-edit 2>&1')
            echo "Merge conflicts resolved and committed"
        else
            if v:shell_error == 0
                echo "Successfully synced with remote"
            else
                echo "Pull completed with message: " . pull_result
            endif
        endif
        
        " Push changes
        echo "Pushing changes..."
        let push_result = system('git push 2>&1')
        if v:shell_error == 0
            echo "Successfully pushed changes"
        else
            echo "Push result: " . push_result
        endif
        
        " Reload current buffer
        execute 'edit!'
        echo "Git sync complete!"
    endfunction
endif

" Map Ctrl+s Ctrl+s to trigger git sync in obsidian-notes
nnoremap <C-s><C-s> :call ObsidianGitSync()<CR>

